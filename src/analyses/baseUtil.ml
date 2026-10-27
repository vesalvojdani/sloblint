open GoblintCil
open GobConfig
module Q = Queries

let is_global (a: Q.ask) (v: varinfo): bool =
  v.vglob || ThreadEscape.has_escaped a v

let is_static (v:varinfo): bool = v.vstorage = Static
let is_volatile variable = Ciltools.is_volatile_tp variable.vtype

let alloca_may_be_empty (bytes: ValueDomain.ID.t) =
  get_string "sem.alloca.zero" <> "null" && ValueDomain.ID.equal_to Z.zero bytes <> `Neq

let is_alloca_block_may_be_empty (a: Q.ask) (v: varinfo) =
  a.f (Q.IsAllocVar v) && not (a.f (Q.IsHeapVar v))
  && alloca_may_be_empty (ValueDomain.SizeDomain.unlift (a.f (Q.BlobSize (AddrOf (Var v, NoOffset)))))

let may_equal_through_empty_alloca (a: Q.ask) (x: Q.AD.t) (y: Q.AD.t) =
  let has_empty_alloca_block = Q.AD.exists (function
      | Addr (v, _) -> is_alloca_block_may_be_empty a v
      | _ -> false)
  in
  let has_non_null = Q.AD.exists (function
      | NullPtr -> false
      | _ -> true)
  in
  (has_empty_alloca_block x && has_non_null y) || (has_empty_alloca_block y && has_non_null x)

let is_always_unknown variable = variable.vstorage = Extern || Ciltools.is_volatile_tp variable.vtype

let is_excluded_from_earlyglobs v = List.mem v.vname (get_string_list "exp.exclude_from_earlyglobs")
let is_excluded_from_invalidation v =  List.mem v.vname (get_string_list "exp.exclude_from_invalidation")
