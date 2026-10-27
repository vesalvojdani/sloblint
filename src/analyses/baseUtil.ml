open GoblintCil
open GobConfig
module Q = Queries

let is_global (a: Q.ask) (v: varinfo): bool =
  v.vglob || ThreadEscape.has_escaped a v

let is_static (v:varinfo): bool = v.vstorage = Static
let is_volatile variable = Ciltools.is_volatile_tp variable.vtype

let is_always_unknown variable = variable.vstorage = Extern || Ciltools.is_volatile_tp variable.vtype

let is_excluded_from_earlyglobs v = List.mem v.vname (get_string_list "exp.exclude_from_earlyglobs")
let is_excluded_from_invalidation v =  List.mem v.vname (get_string_list "exp.exclude_from_invalidation")

type alloc_result = { may_be_null: bool; may_be_pointer: bool }

let alloc_result ?count (loc: Q.AllocationLocation.t) (size: ValueDomain.ID.t) =
  let zero_option, fail_option =
    match loc with
    | Heap -> "sem.malloc.zero", "sem.malloc.fail"
    | Stack -> "sem.alloca.zero", "sem.alloca.fail"
  in
  (* Whether an allocation of zero bytes returns the null pointer, a valid pointer, or both cases need to be considered. *)
  let alloc_zero_null, alloc_zero_pointer =
    match get_string zero_option with
    | "null" -> true, false
    | "pointer" -> false, true
    | "either" -> true, true
    | _ -> assert false
  in
  (* The number of bytes requested is [size], or [count * size] with [count] (calloc).
     The product is zero exactly when [count] or [size] is zero: calloc does not wrap around a product that does not fit in size_t, but fails, which is the case of [fail_option]. *)
  let cmps_with_zero = List.map (ValueDomain.ID.equal_to Z.zero) (size :: Option.to_list count) in
  let bytes_may_be_zero = List.exists (fun cmp -> cmp <> `Neq) cmps_with_zero in
  let bytes_may_be_nonzero = List.for_all (fun cmp -> cmp <> `Eq) cmps_with_zero in
  let may_be_null = (bytes_may_be_nonzero && get_bool fail_option) || (bytes_may_be_zero && alloc_zero_null) in
  let may_be_pointer = bytes_may_be_nonzero || alloc_zero_pointer in
  (* Without sem.malloc.fail, the result leaves out the null pointer that a failing heap allocation of a nonzero size returns.
     alloca does not return the null pointer when it fails, so sem.alloca.fail assumes nothing. *)
  begin match loc with
    | Heap when bytes_may_be_nonzero && not may_be_null ->
      Assumptions.add "Heap allocation does not fail: functions that allocate on the heap, such as malloc, calloc and realloc, return the null pointer only when the number of bytes requested is zero"
    | _ -> ()
  end;
  { may_be_null; may_be_pointer }
