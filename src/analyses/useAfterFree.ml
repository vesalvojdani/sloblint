(** An analysis for the detection of use-after-free vulnerabilities ([useAfterFree]). *)

open GoblintCil
open Analyses
open MessageCategory
open AnalysisStateUtil

module AllocaVars = SetDomain.ToppedSet(CilType.Varinfo)(struct let topname = "All alloca() Variables" end)
module HeapVars = SetDomain.ToppedSet(CilType.Varinfo)(struct let topname = "All Heap Variables" end)

(* Heap vars created by alloca() and deallocated at function exit * Heap vars deallocated by free() *)
module StackAndHeapVars = Lattice.Prod(AllocaVars)(HeapVars)

module ThreadIdToJoinedThreadsMap = MapDomain.MapBot(ThreadIdDomain.ThreadLifted)(ConcDomain.FiniteMustThreadSet)

module Spec : Analyses.MCPSpec =
struct
  include Analyses.IdentityUnitContextsSpec

  let name () = "useAfterFree"

  module D = StackAndHeapVars
  module G = ThreadIdToJoinedThreadsMap
  module V = VarinfoV

  (* HELPER FUNCTIONS *)

  let get_current_threadid man =
    man.ask Queries.CurrentThreadId

  let get_joined_threads man =
    man.ask Queries.MustJoinedThreads

  let warn_for_multi_threaded_access man ?(is_free = false) (heap_var:varinfo) behavior cwe_number =
    let freeing_threads = man.global heap_var in
    (* If we're single-threaded or there are no threads freeing the memory, we have nothing to WARN about *)
    if not (ThreadFlag.has_ever_been_multi (Analyses.ask_of_man man)) || G.is_empty freeing_threads then ()
    else begin
      let other_possibly_started current tid joined_threads =
        match tid with
        | `Lifted tid when (ThreadId.Thread.equal current tid && ThreadId.Thread.is_unique current) ->
          (* if our own (unique) thread is started here, that is not a problem *)
          false
        | `Lifted tid ->
          let created_threads = man.ask Queries.CreatedThreads in
          let not_started = MHP.definitely_not_started (current, created_threads) tid in
          let possibly_started = not not_started in
          (* If [current] is possibly running together with [tid], but is also joined before the free() in [tid], then no need to WARN *)
          possibly_started && not (ConcDomain.FiniteMustThreadSet.mem_lifted current joined_threads)
        | `Top -> true
        | `Bot -> false
      in
      let equal_current current tid joined_threads =
        match tid with
        | `Lifted tid ->
          ThreadId.Thread.equal current tid
        | `Top -> true
        | `Bot -> false
      in
      let bug_name = if is_free then "Double Free" else "Use After Free" in
      match get_current_threadid man with
      | `Lifted current ->
        let possibly_started = G.exists (other_possibly_started current) freeing_threads in
        if possibly_started then begin
          if is_free then set_mem_safety_flag InvalidFree else set_mem_safety_flag InvalidDeref;
          M.warn ~category:(Behavior behavior) ~tags:[CWE cwe_number] "There's a thread that's been started in parallel with the memory-freeing threads for heap variable %a. %s might occur" CilType.Varinfo.pretty heap_var bug_name
        end
        else begin
          let current_is_unique = ThreadId.Thread.is_unique current in
          let any_equal_current threads = G.exists (equal_current current) threads in
          if not current_is_unique && any_equal_current freeing_threads then begin
            if is_free then set_mem_safety_flag InvalidFree else set_mem_safety_flag InvalidDeref;
            M.warn ~category:(Behavior behavior) ~tags:[CWE cwe_number] "Current thread is not unique and a %s might occur for heap variable %a" bug_name CilType.Varinfo.pretty heap_var
          end
          else if HeapVars.mem heap_var (snd man.local) then begin
            if is_free then set_mem_safety_flag InvalidFree else set_mem_safety_flag InvalidDeref;
            M.warn ~category:(Behavior behavior) ~tags:[CWE cwe_number] "%s might occur in current unique thread %a for heap variable %a" bug_name ThreadIdDomain.Thread.pretty current CilType.Varinfo.pretty heap_var
          end
        end
      | `Top ->
        if is_free then set_mem_safety_flag InvalidFree else set_mem_safety_flag InvalidDeref;
        M.warn ~category:(Behavior behavior) ~tags:[CWE cwe_number] "CurrentThreadId is top. %s might occur for heap variable %a" bug_name CilType.Varinfo.pretty heap_var
      | `Bot ->
        M.warn ~category:MessageCategory.Analyzer "CurrentThreadId is bottom"
    end

  let side_effect_mem_free man freed_heap_vars threadid joined_threads =
    let side_effect_globals_to_heap_var heap_var =
      let current_globals = man.global heap_var in
      let globals_to_side_effect = G.add threadid joined_threads current_globals in
      man.sideg heap_var globals_to_side_effect
    in
    HeapVars.iter side_effect_globals_to_heap_var freed_heap_vars


  (* TRANSFER FUNCTIONS *)

  let enter man (lval:lval option) (f:fundec) (args:exp list) : (D.t * D.t) list =
    let caller_state = man.local in
    (* TODO: The 2nd component of the callee state needs to contain only the heap vars from the caller state which are reachable from: *)
    (* * Global program variables *)
    (* * The callee arguments *)
    [caller_state, (AllocaVars.empty (), snd caller_state)]

  let combine_env man (lval:lval option) fexp (f:fundec) (args:exp list) fc (callee_local:D.t) (f_ask:Queries.ask) : D.t =
    let (caller_stack_state, caller_heap_state) = man.local in
    let callee_stack_state = fst callee_local in
    let callee_heap_state = snd callee_local in
    (* Put all alloca()-vars together with all freed() vars in the caller's second component *)
    (* Don't change caller's first component => caller hasn't exited yet *)
    let callee_combined_state = HeapVars.join callee_stack_state callee_heap_state in
    (caller_stack_state, HeapVars.join caller_heap_state callee_combined_state)

  (** The heap vars among the addresses [ad]. *)
  let heap_vars_of man ad =
    Queries.AD.fold (fun addr heap_vars ->
        match addr with
        | Queries.AD.Addr.Addr (var,_) when man.ask (Queries.IsAllocVar var) && man.ask (Queries.IsHeapVar var) -> HeapVars.add var heap_vars
        | _ -> heap_vars
      ) ad (HeapVars.empty ())

  (** [state] after the current thread has freed the heap vars [freed_heap_vars].
      The freeing thread is also side-effected to the global of each of them, for the accesses of other threads. *)
  let free_heap_vars man state freed_heap_vars =
    side_effect_mem_free man freed_heap_vars (get_current_threadid man) (get_joined_threads man);
    (fst state, HeapVars.join (snd state) freed_heap_vars)

  (** [state] after a call of [f] that frees the memory the addresses [ad] hold, except the heap vars [except].
      Heap vars among [ad] are recorded as freed.
      If [ad] may also hold the unknown pointer, the memory freed through it cannot be named, and the assumption that it is not accessed afterwards is declared. *)
  let free_addresses man state (f:varinfo) ?(except = HeapVars.empty ()) ad =
    if Queries.AD.may_be_unknown ad then
      Assumptions.add "Memory that %s frees through an unknown pointer is assumed not to be accessed afterwards (useAfterFree)" f.vname;
    free_heap_vars man state (HeapVars.diff (heap_vars_of man ad) except)

  let special man (lval:lval option) (f:varinfo) (arglist:exp list) : D.t =
    let state = man.local in
    let desc = LibraryFunctions.find f in
    match desc.special arglist with
    | Free ptr ->
      (* TODO: do this using Free Access events? *)
      begin match man.ask (Queries.MayPointTo ptr) with
        | ad when not (Queries.AD.is_top ad) -> free_heap_vars man state (heap_vars_of man ad)
        | _ -> state
      end
    | Realloc { ptr; _ } ->
      (* [realloc] frees its old block if it moves it. The analysis does not decide whether it does, so the old block is recorded as freed.
         If [realloc] fails (only with [sem.malloc.fail]) the old block stays valid, and a use of it after the failure is reported. *)
      free_addresses man state f (man.ask (Queries.MayPointTo ptr))
    | Alloca _ ->
      (* Create fresh heap var for the alloca() call *)
      begin match man.ask (Queries.AllocVar Stack) with
        | `Lifted v -> (AllocaVars.add v (fst state), snd state)
        | _ -> state
      end
    | _ ->
      (* Only deep [Free] accesses are recorded. The functions with a shallow one ([pthread_mutex_destroy], [regfree],
         [inflateEnd], ...) destroy the object in place rather than free the block it lives in, and recording it would
         make [pthread_mutex_destroy(m); free(m);] a double free. *)
      LibraryDesc.Accesses.fold desc.accs (fun {kind; deep} exp state ->
          match kind, deep with
          | Free, true ->
            (* The heap vars the argument points to are not recorded: the functions with a deep [Free] access either free
               memory of the library, which has no heap var, or the contents of the object the argument points to
               ([getline] the buffer in [*lineptr], [xdr_free] the members of [*objp]), not the object itself.
               The freed contents can be a block of an excluded heap var if that heap var may stand for several blocks
               ([Queries.IsMultiple]: every heap var at the default [ana.malloc.unique_address_count], and otherwise one
               allocated in a loop, by an allocation wrapper called twice, or in a thread that is not unique), or if the
               argument may point to several heap vars, one of which holds a pointer to the block another one stands for.
               Neither case is recorded, and the call declares that. *)
            let pointed_to = heap_vars_of man (man.ask (Queries.MayPointTo exp)) in
            if HeapVars.cardinal pointed_to > 1 || HeapVars.exists (fun v -> man.ask (Queries.IsMultiple v)) pointed_to then
              Assumptions.add "%s is assumed not to free a block allocated by the same malloc, calloc or realloc call as an object that %a may point to (the call inside an allocation wrapper, unless the wrapper is in ana.malloc.wrappers) (useAfterFree)" f.vname d_exp exp;
            free_addresses man state f ~except:pointed_to (man.ask (Queries.ReachableFrom exp))
          | _ -> state
        ) arglist state

  let startstate v = D.bot ()
  let exitstate v = D.top ()

  let event man e oman =
    match e with
    | Events.Access {exp; ad; kind; reach} ->
      (* must use original (pre-assign, etc) man queries *)
      let is_free = kind = Free in
      let freed_heap_vars = snd oman.local in
      let undefined_behavior = if is_free then Undefined DoubleFree else Undefined UseAfterFree in
      let cwe_number = if is_free then 415 else 416 in
      let warn_for_heap_var v =
        if HeapVars.mem v freed_heap_vars then begin
          if is_free then (
            set_mem_safety_flag InvalidFree;
            Checks.warn Checks.Category.DoubleFree "lval (%s) points to a maybe freed memory region" v.vname)
          else (
            set_mem_safety_flag InvalidDeref;
            Checks.warn Checks.Category.InvalidMemoryAccess "lval (%s) points to a maybe freed memory region" v.vname
          );
          M.warn ~category:(Behavior undefined_behavior) ~tags:[CWE cwe_number] "lval (%s) points to a maybe freed memory region" v.vname;
        end else if is_free then
          Checks.safe Checks.Category.DoubleFree
        else
          Checks.safe Checks.Category.InvalidMemoryAccess
      in
      if not (Queries.AD.is_top ad) then begin
        let pointed_to_heap_vars =
          Queries.AD.fold (fun addr vars ->
              match addr with
              | Queries.AD.Addr.Addr (v,_) when oman.ask (Queries.IsAllocVar v) -> v :: vars
              | _ -> vars
            ) ad []
        in
        (* Warn for all heap vars that the lval possibly points to *)
        List.iter warn_for_heap_var pointed_to_heap_vars;
        (* Warn for a potential multi-threaded UAF for all heap vars that the lval possibly points to *)
        List.iter (fun heap_var -> warn_for_multi_threaded_access oman ~is_free heap_var undefined_behavior cwe_number) pointed_to_heap_vars
      end;
      man.local
    | _ ->
      man.local
end

let _ =
  MCP.register_analysis ~dep:["access"] (module Spec : MCPSpec)
