(** Basic analysis utilities. *)

open GoblintCil

val is_global: Queries.ask -> varinfo -> bool
val is_static: varinfo -> bool
val is_volatile: varinfo -> bool
val is_always_unknown: varinfo -> bool
val is_excluded_from_earlyglobs: varinfo -> bool
val is_excluded_from_invalidation: varinfo -> bool

(** What an allocation may return. *)
type alloc_result = {
  may_be_null: bool; (** The allocation may return the null pointer. *)
  may_be_pointer: bool; (** The allocation may return a pointer to new memory. *)
}

(** [alloc_result loc bytes] is what an allocation of [bytes] bytes on the stack or the heap ([loc]) may return, as the options [sem.alloca.zero] and [sem.alloca.fail], or [sem.malloc.zero] and [sem.malloc.fail], say.
    For a heap allocation whose size may be nonzero and whose result does not include the null pointer, which holds when [sem.malloc.fail] is disabled, it declares the assumption "Heap allocation does not fail" from docs/user-guide/assumptions.md. *)
val alloc_result: Queries.AllocationLocation.t -> ValueDomain.ID.t -> alloc_result
