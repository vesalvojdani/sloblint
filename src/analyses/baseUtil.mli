(** Basic analysis utilities. *)

open GoblintCil

val is_global: Queries.ask -> varinfo -> bool
val is_static: varinfo -> bool
val is_volatile: varinfo -> bool

(** [alloca_may_be_empty bytes] is whether [alloca] of [bytes] bytes may return a pointer to a block of size zero:
    [bytes] may be zero and the option [sem.alloca.zero] is not [null]. *)
val alloca_may_be_empty: ValueDomain.ID.t -> bool

(** [is_alloca_block_may_be_empty ask v] is whether [v] is a block allocated by [alloca] (see [Queries.IsAllocVar] and [Queries.IsHeapVar]) whose size ([Queries.BlobSize]) may be zero, as {!alloca_may_be_empty} decides. *)
val is_alloca_block_may_be_empty: Queries.ask -> varinfo -> bool

(** [may_equal_through_empty_alloca ask x y] is whether a pointer to an address in [x] may be equal to a pointer to an address in [y] although the two addresses are different:
    one of [x] and [y] contains the address of an [alloca] block that may have size zero ({!is_alloca_block_may_be_empty}), and the other contains an address other than the null pointer.
    A block of size zero occupies no memory, so its address may be the address of another object:
    compiled with clang -O0, [alloca(0)] returns the current stack pointer, which is also the address of the block the next [alloca] allocates. *)
val may_equal_through_empty_alloca: Queries.ask -> Queries.AD.t -> Queries.AD.t -> bool
val is_always_unknown: varinfo -> bool
val is_excluded_from_earlyglobs: varinfo -> bool
val is_excluded_from_invalidation: varinfo -> bool
