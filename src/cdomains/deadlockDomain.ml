(** Deadlock domain. *)

module Lock = LockDomain.Addr
module LockEvent = Printable.Prod3 (Lock) (Node) (MCPAccess.A)

module MayLockEvents = SetDomain.ToppedSet (LockEvent) (struct let topname = "All lock events" end)

(** Locks that may have been held more than once since the thread started: a
    lock is added when it is locked while a lock event of a lock that may be
    the same mutex is in {!MayLockEvents}, and is never removed. *)
module MayRelockedLocks = SetDomain.ToppedSet (Lock) (struct let topname = "All locks" end)
