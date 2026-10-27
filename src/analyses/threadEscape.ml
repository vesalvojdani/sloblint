(** Escape analysis for thread-local variables ([escape]). *)

open GoblintCil
open Analyses

module M = Messages
module AD = Queries.AD

let has_escaped (ask: Queries.ask) (v: varinfo): bool =
  assert (not v.vglob);
  if not v.vaddrof then
    false (* Cannot have escaped without taking address. Override provides extra precision for degenerate ask in base to_value_domain_ask used for partitioned arrays. *)
  else if GobConfig.get_bool "exp.single-threaded" then
    false (* Cannot have escaped if no other threads are assumed to exist. Override provides extra precision for analyzing single-threaded programs without escape analysis. *)
  else
    ask.f (Queries.MayEscape v)

module Spec =
struct
  include Analyses.IdentitySpec

  module ThreadIdSet = SetDomain.Make (ThreadIdDomain.ThreadLifted)

  let name () = "escape"
  module D = EscapeDomain.EscapedVars
  include Analyses.ValueContexts(D)
  module V = VarinfoV
  module G = ThreadIdSet

  let reachable (ask: Queries.ask) e: D.t =
    match ask.f (Queries.ReachableFrom e) with
    | ad when not (Queries.AD.is_top ad) ->
      let to_extra addr set =
        match addr with
        | Queries.AD.Addr.Addr (v,_) -> D.add v set
        | _ -> set
      in
      Queries.AD.fold to_extra ad (D.empty ())
    (* Ignore soundness warnings, as invalidation proper will raise them. *)
    | ad ->
      if M.tracing then M.tracel "escape" "reachable %a: %a" d_exp e Queries.AD.pretty ad;
      D.empty ()

  let mpt (ask: Queries.ask) e: D.t =
    match ask.f (Queries.MayPointTo e) with
    | ad when not (AD.is_top ad) ->
      let to_extra addr set =
        match addr with
        | AD.Addr.Addr (v,_) -> D.add v set
        | _ -> set
      in
      AD.fold to_extra (AD.remove UnknownPtr ad) (D.empty ())
    (* Ignore soundness warnings, as invalidation proper will raise them. *)
    | ad ->
      if M.tracing then M.tracel "escape" "mpt %a: %a" d_exp e AD.pretty ad;
      D.empty ()

  (** Operands of the conversions of a pointer to an integer type in [e] whose
      integer may become part of the value of [e].
      Such a conversion exposes the pointer's address: the integer, or one equal
      to it, may later be converted back to a pointer and used to access the memory
      (C11 6.3.2.3p5-6, 7.20.1.4). Base evaluates the conversion to an integer that
      keeps no address, so {!reachable} of an expression holding the integer finds
      nothing. Not included are the [PointerConversion] casts that CIL inserts to
      compare or subtract two pointers, conversions to [_Bool], and conversions
      inside the operands of comparisons, of [!], [&&] and [||], and inside the
      condition of [?:], whose results are 0 or 1. [e] is constant-folded first,
      as Base does, so [offsetof] written as [(size_t)&((T * )0)->f] is a constant. *)
  let exposed_pointers (e: exp): exp list =
    let acc = ref [] in
    let is_address_integer t =
      match Cil.unrollType t with
      | TInt (IBool, _) -> false
      | TInt _ | TEnum _ -> true
      | _ -> false
    in
    let is_pointer e =
      try Cil.isPointerType (Cilfacade.typeOf e) with Cilfacade.TypeOfError _ -> false
    in
    let visitor = object (self)
      inherit Cil.nopCilVisitor
      method! vexpr = function
        | CastE (kind, t, e') when kind <> PointerConversion && is_address_integer t && is_pointer e' ->
          acc := e' :: !acc;
          DoChildren
        | BinOp ((Lt | Gt | Le | Ge | Eq | Ne | LAnd | LOr), _, _, _)
        | UnOp (LNot, _, _) ->
          SkipChildren
        | Question (_, e2, e3, _) ->
          ignore (Cil.visitCilExpr self e2);
          ignore (Cil.visitCilExpr self e3);
          SkipChildren
        | _ -> DoChildren
    end
    in
    ignore (Cil.visitCilExpr visitor (Cil.constFold true e));
    !acc

  let thread_id man =
    man.ask Queries.CurrentThreadId

  (** Emit an escape event:
      Only necessary when code has ever been multithreaded,
      or when about to go multithreaded. *)
  let emit_escape_event man escaped =
    (* avoid emitting unnecessary event *)
    if not (D.is_empty escaped) then
      man.emit (Events.Escape escaped)

  (** Side effect escapes: In contrast to the emitting the event, side-effecting is
      necessary in single threaded mode, since we rely on escape status in Base
      for passing locals reachable via globals *)
  let side_effect_escape man escaped threadid =
    let threadid = G.singleton threadid in
    D.iter (fun v ->
        man.sideg v threadid) escaped

  (* queries *)
  let query man (type a) (q: a Queries.t): a Queries.result =
    match q with
    | Queries.MayEscape v ->
      let threads = man.global v in
      if ThreadIdSet.is_empty threads then
        false
      else begin
        let other_possibly_started current = function
          | `Lifted tid when (ThreadId.Thread.equal current tid && ThreadId.Thread.is_unique current) ->
            (* if our own (unique) thread is started here, that is not a problem *)
            false
          | `Lifted tid ->
            let threads = man.ask Queries.CreatedThreads in
            let not_started = MHP.definitely_not_started (current, threads) tid in
            let possibly_started = not not_started in
            possibly_started
          | `Top -> true
          | `Bot -> false
        in
        let equal_current current = function
          | `Lifted tid ->
            ThreadId.Thread.equal current tid
          | `Top -> true
          | `Bot -> false
        in
        match man.ask Queries.CurrentThreadId with
        | `Lifted current ->
          let possibly_started = ThreadIdSet.exists (other_possibly_started current) threads in
          if possibly_started then
            true
          else
            let current_is_unique = ThreadId.Thread.is_unique current in
            let any_equal_current threads = ThreadIdSet.exists (equal_current current) threads in
            if not current_is_unique && any_equal_current threads then
              (* Another instance of the non-unique current thread may have escaped the variable *)
              true
            else
              (* Check whether current unique thread has escaped the variable *)
              D.mem v man.local
        | `Top ->
          true
        | `Bot ->
          M.warn ~category:MessageCategory.Analyzer "CurrentThreadId is bottom.";
          false
      end
    | _ -> Queries.Result.top q

  let escape_rval man ask (rval:exp) =
    let escaped = reachable ask rval in
    let escaped = D.filter (fun v -> not v.vglob) escaped in

    let thread_id = thread_id man in
    side_effect_escape man escaped thread_id;
    if ThreadFlag.has_ever_been_multi ask then (* avoid emitting unnecessary event *)
      emit_escape_event man escaped;
    escaped

  (** Records as escaped what is {!reachable} in [ask] from the {!exposed_pointers}
      of [es], and returns the non-global variables among it. The escape event is
      emitted if the program has ever been multithreaded according to [multi_ask],
      which defaults to [ask]. *)
  let escape_exposed ?multi_ask man ask (es: exp list): D.t =
    let multi_ask = Option.value multi_ask ~default:ask in
    let escaped = List.fold_left (fun acc e ->
        List.fold_left (fun acc p ->
            D.join acc (reachable ask p)
          ) acc (exposed_pointers e)
      ) (D.empty ()) es
    in
    let escaped = D.filter (fun v -> not v.vglob) escaped in
    side_effect_escape man escaped (thread_id man);
    if ThreadFlag.has_ever_been_multi multi_ask then
      emit_escape_event man escaped;
    escaped

  let lval_exps (lval: lval option): exp list =
    List.map (fun lval -> Lval lval) (Option.to_list lval)

  (* transfer functions *)
  let assign man (lval:lval) (rval:exp) : D.t =
    let ask = Analyses.ask_of_man man in
    let local = D.join man.local (escape_exposed man ask [Lval lval; rval]) in
    let vs = mpt ask (AddrOf lval) in
    if D.exists (fun v -> v.vglob || has_escaped ask v) vs then (
      let escaped = escape_rval man ask rval in
      D.join local escaped
    ) else begin
      local
    end

  let return man (exp:exp option) (f:fundec) : D.t =
    D.join man.local (escape_exposed man (Analyses.ask_of_man man) (Option.to_list exp))

  (* [enter] cannot emit the escape event, so the addresses that the arguments of a call to a defined function expose escape when the call returns, not during the call.
     The event is emitted if the program is multithreaded by the end of the callee. *)
  let combine_env man (lval:lval option) (fexp:exp) f args fc au f_ask : D.t =
    D.join au (escape_exposed ~multi_ask:f_ask man (Analyses.ask_of_man man) args)

  let combine_assign man (lval:lval option) (fexp:exp) f args fc au f_ask : D.t =
    let ask = Analyses.ask_of_man man in
    let local = D.join man.local (escape_exposed ~multi_ask:f_ask man ask (lval_exps lval)) in
    match lval with
    | Some lval when D.exists (fun v -> v.vglob || has_escaped ask v) (mpt ask (AddrOf lval)) ->
      let rval = Lval (ReturnUtil.return_lval ()) in
      let escaped = escape_rval man f_ask rval in (* Using f_ask because the return value is only accessible in the context of that function at this point *)
      D.join local escaped
    | _ -> local

  let special man (lval: lval option) (f:varinfo) (args:exp list) : D.t =
    let ask = Analyses.ask_of_man man in
    let local = D.join man.local (escape_exposed man ask (lval_exps lval @ args)) in
    let desc = LibraryFunctions.find f in
    match desc.special args, f.vname, args with
    | Globalize ptr, _, _ ->
      let escaped = escape_rval man ask ptr in
      D.join local escaped
    | _, "pthread_setspecific" , [key; pt_value] ->
      let escaped = escape_rval man ask pt_value in
      D.join local escaped
    | _ -> local

  let startstate v = D.bot ()
  let exitstate  v = D.bot ()

  let threadenter man ~multiple lval f args =
    [D.bot ()]

  let threadspawn man ~multiple lval f args fman =
    D.join man.local @@
    match args with
    | [ptc_arg] ->
      (* not reusing fman.local to avoid unnecessarily early join of extra *)
      let escaped = reachable (Analyses.ask_of_man man) ptc_arg in
      let escaped = D.filter (fun v -> not v.vglob) escaped in
      if M.tracing then M.tracel "escape" "%a: %a" d_exp ptc_arg D.pretty escaped;
      let thread_id = thread_id man in
      emit_escape_event man escaped;
      side_effect_escape man escaped thread_id;
      escaped
    | _ -> D.bot ()

  let event man e oman =
    match e with
    | Events.EnterMultiThreaded ->
      let escaped = man.local in
      let thread_id = thread_id man in
      emit_escape_event man escaped;
      side_effect_escape man escaped thread_id;
      man.local
    | _ -> man.local
end

let _ =
  MCP.register_analysis (module Spec : MCPSpec)
