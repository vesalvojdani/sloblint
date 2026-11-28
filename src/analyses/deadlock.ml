(** Deadlock analysis ([deadlock]). *)

open Batteries
open GoblintCil
open Analyses
open DeadlockDomain


module Spec =
struct

  module LockEventPair = Printable.Prod (LockEvent) (LockEvent)
  module MayLockEventPairs = SetDomain.Make (LockEventPair)

  module Arg =
  struct
    (** Lock events of the locks that may be held, and the locks that may
        have been held more than once since the thread started. *)
    module D =
    struct
      include Lattice.Prod (MayLockEvents) (MayRelockedLocks)
      let empty () = (MayLockEvents.empty (), MayRelockedLocks.empty ())
    end
    module V =
    struct
      include Lock
      let is_write_only _ = true
    end

    module G = MapDomain.MapBot (Lock) (MayLockEventPairs)

    let side_lock_event_pair man ((before_node, _, _) as before) ((after_node, _, _) as after) =
      if !AnalysisState.should_warn then
        man.sideg before_node (G.singleton after_node (MayLockEventPairs.singleton (before, after)))

    let part_access man: MCPAccess.A.t =
      Obj.obj (man.ask (PartAccess Point))

    (** Whether [l1] and [l2] may be the same mutex: true unless
        [Lock.semantic_equal] reports them as different. *)
    let may_equal l1 l2 = Option.default true (Lock.semantic_equal l1 l2)

    let add man ((l, _): LockDomain.AddrRW.t) =
      let (events, relocked) = man.local in
      let after: LockEvent.t = (l, man.prev_node, part_access man) in (* use oman for access to use locksets before event *)
      MayLockEvents.iter (fun before ->
          side_lock_event_pair man before after
        ) events;
      let relocked =
        if MayLockEvents.exists (fun (e, _, _) -> may_equal l e) events then
          MayRelockedLocks.add l relocked
        else
          relocked
      in
      (MayLockEvents.add after events, relocked)

    (** Removes the lock events of [l] from the may-lockset, unless [l] may be
        a recursive mutex that may be held more than once: [l] is the address
        of a variable, [Queries.MutexType] does not report it as non-recursive,
        and a lock that may be the same mutex is in [MayRelockedLocks]. Such a
        mutex may still be held after one unlock, so its events are kept. *)
    let remove man l =
      let (events, relocked) = man.local in
      let may_be_recursive = match Lock.to_mval l with
        | Some (v, o) ->
          begin match man.ask (Queries.MutexType (v, Offset.Unit.of_offs o)) with
            | `Lifted MutexAttrDomain.MutexKind.NonRec -> false
            | _ -> true
          end
        | None -> false
      in
      if may_be_recursive && MayRelockedLocks.exists (may_equal l) relocked then
        man.local
      else
        let inLockAddrs (e, _, _) = Lock.equal l e in
        (MayLockEvents.filter (neg inLockAddrs) events, relocked)
  end

  include LocksetAnalysis.MakeMay (Arg)
  let name () = "deadlock"

  module G = Arg.G (* help type checker using explicit constraint *)

  let query man (type a) (q: a Queries.t): a Queries.result =
    match q with
    | WarnGlobal g ->
      let g: V.t = Obj.obj g in

      let module LH = Hashtbl.Make (Lock) in
      let module LS = Set.Make (Lock) in
      (* TODO: find all cycles/SCCs *)
      let global_visited_locks = LH.create 100 in

      let may_equal l1 l2 = match l1, l2 with
        | ValueDomain.Addr.UnknownPtr, _
        | _, ValueDomain.Addr.UnknownPtr ->
          true
        | _, _ -> Lock.equal l1 l2
      in

      (* DFS *)
      let rec iter_lock (path_visited_locks: LS.t) (path_visited_lock_event_pairs: LockEventPair.t list) (lock: Lock.t) =
        if LS.mem lock path_visited_locks || LS.mem ValueDomain.Addr.UnknownPtr path_visited_locks || (not (LS.is_empty path_visited_locks) && lock = ValueDomain.Addr.UnknownPtr) then (
          (* cycle may not return to first lock, but an intermediate one, cut off the non-cyclic stem *)
          let path_visited_lock_event_pairs =
            (* path_visited_lock_event_pairs cannot be empty *)
            List.hd path_visited_lock_event_pairs ::
            List.take_while (fun (_, (after_lock, _, _)) ->
                not (may_equal after_lock lock)
              ) (List.tl path_visited_lock_event_pairs)
          in
          let mhp =
            Seq.product (List.to_seq path_visited_lock_event_pairs) (List.to_seq path_visited_lock_event_pairs)
            |> Seq.for_all (fun (((_, (_, _, access1)) as p1), ((_, (_, _, access2)) as p2)) ->
                LockEventPair.equal p1 p2 || MCPAccess.A.may_race access1 access2
              )
          in
          if mhp then (
            (* normalize path_visited_lock_event_pairs such that we don't get the same cycle multiple times, starting from different events *)
            let min = List.min ~cmp:LockEventPair.compare path_visited_lock_event_pairs in
            let (mini, _) = List.findi (fun i x -> LockEventPair.equal min x) path_visited_lock_event_pairs in
            let (init, tail) = List.split_at mini path_visited_lock_event_pairs in
            let normalized = List.rev_append init (List.rev tail) in (* backwards to get correct printout order *)
            let msgs = List.concat_map (fun ((before_lock, before_node, before_access), (after_lock, after_node, after_access)) ->
                [
                  (Pretty.dprintf "lock before: %a with %a" Lock.pretty before_lock MCPAccess.A.pretty before_access, Some (M.Location.Node before_node));
                  (Pretty.dprintf "lock after: %a with %a" Lock.pretty after_lock MCPAccess.A.pretty after_access, Some (M.Location.Node after_node));
                ]
              ) normalized
            in
            M.msg_group Warning ~category:Deadlock "Locking order cycle" msgs
          )
        )
        else if not (LH.mem global_visited_locks lock) then begin
          LH.replace global_visited_locks lock ();
          let new_path_visited_locks = LS.add lock path_visited_locks in
          G.iter (fun to_lock lock_event_pairs ->
              MayLockEventPairs.iter (fun lock_event_pair ->
                  let new_path_visited_lock_event_pairs' = lock_event_pair :: path_visited_lock_event_pairs in
                  iter_lock new_path_visited_locks new_path_visited_lock_event_pairs' to_lock
                ) lock_event_pairs
            ) (man.global lock)
        end
      in

      Timing.wrap ~args:[("lock", `String (Lock.show g))] "deadlock" (iter_lock LS.empty []) g
    | _ -> Queries.Result.top q
end

let _ =
  MCP.register_analysis ~dep:["mutexEvents"] (module Spec : MCPSpec)
