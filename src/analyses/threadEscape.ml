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

  (** Whether [value] may hold an address other than the null pointer, as Base
      keeps it: an unknown value may, an array is read at an unknown index, and an
      integer holds none. *)
  let rec may_hold_address (ask: Queries.ask) (value: Queries.VD.t): bool =
    match value with
    | Top -> true
    | Address a -> not (AD.is_empty (AD.remove NullPtr a))
    | Struct s -> ValueDomain.Structs.fold (fun _ v acc -> acc || may_hold_address ask v) s false
    | Union (_, v) -> may_hold_address ask v
    | Array a -> may_hold_address ask (ValueDomain.CArrays.get (Queries.to_value_domain_ask ask) a (None, ValueDomain.IndexDomain.top ()))
    | Blob (v, _, _) -> may_hold_address ask v
    | Int _ | Float _ | Thread _ | JmpBuf _ | Mutex | MutexAttr _ | Bot -> false

  (** Variables that a copy of the memory [src] points to, as [memcpy] makes, may
      make reachable from the destination: for each variable [src] may point to,
      everything {!reachable} from the address of the whole variable, whichever
      offset [src] points to and however many bytes are copied. That set contains
      the variable itself whether or not its contents point back to it, so the
      variable is left out only when nothing else is reachable from it and its
      value holds no address ({!may_hold_address}). A function is left out: Base
      keeps no value for it. *)
  let reachable_by_copy (ask: Queries.ask) (src: exp): D.t =
    D.fold (fun v acc ->
        if Cil.isFunctionType v.vtype then
          acc
        else
          let r = reachable ask (AddrOf (Var v, NoOffset)) in
          if D.equal r (D.singleton v) && not (may_hold_address ask (ask.f (Queries.EvalValue (Lval (Var v, NoOffset))))) then
            acc
          else
            D.join acc r
      ) (mpt ask src) (D.empty ())

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

  (** Records the non-global variables of [escaped] as escaped. *)
  let escape_vars man ask (escaped: D.t) =
    let escaped = D.filter (fun v -> not v.vglob) escaped in

    let thread_id = thread_id man in
    side_effect_escape man escaped thread_id;
    if ThreadFlag.has_ever_been_multi ask then (* avoid emitting unnecessary event *)
      emit_escape_event man escaped;
    escaped

  let escape_rval man ask (rval:exp) = escape_vars man ask (reachable ask rval)

  (* transfer functions *)
  let assign man (lval:lval) (rval:exp) : D.t =
    let ask = Analyses.ask_of_man man in
    let vs = mpt ask (AddrOf lval) in
    if D.exists (fun v -> v.vglob || has_escaped ask v) vs then (
      let escaped = escape_rval man ask rval in
      D.join man.local escaped
    ) else begin
      man.local
    end

  let combine_assign man (lval:lval option) (fexp:exp) f args fc au f_ask : D.t =
    let ask = Analyses.ask_of_man man in
    match lval with
    | Some lval when D.exists (fun v -> v.vglob || has_escaped ask v) (mpt ask (AddrOf lval)) ->
      let rval = Lval (ReturnUtil.return_lval ()) in
      let escaped = escape_rval man f_ask rval in (* Using f_ask because the return value is only accessible in the context of that function at this point *)
      D.join man.local escaped
    | _ -> man.local

  let special man (lval: lval option) (f:varinfo) (args:exp list) : D.t =
    let desc = LibraryFunctions.find f in
    match desc.special args, f.vname, args with
    | Globalize ptr, _, _ ->
      let escaped = escape_rval man (Analyses.ask_of_man man) ptr in
      D.join man.local escaped
    | _, "pthread_setspecific" , [key; pt_value] ->
      let escaped = escape_rval man (Analyses.ask_of_man man) pt_value in
      D.join man.local escaped
    | Memcpy { dest; src; _ }, _, _ ->
      (* As [assign] of [*src] to [*dest]: when [dest] may point to a global or escaped variable, escapes what the copy may make reachable from it. *)
      let ask = Analyses.ask_of_man man in
      if D.exists (fun v -> v.vglob || has_escaped ask v) (mpt ask dest) then
        D.join man.local (escape_vars man ask (reachable_by_copy ask src))
      else
        man.local
    | _ -> man.local

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
