module ID = IntDomain.IntDomTuple
module FD = FloatDomain.FloatDomTupleImpl

module IndexDomain = (* TODO: hide type t = ID.t, require explicit (un)lift *)
struct
  include IntDomain.IntDomWithDefaultIkind (ID) (IntDomain.PtrDiffIkind) (* TODO: add ptrdiff cast into to_int? *)
  let lift x = ID.cast_to ~kind:Internal (Cilfacade.ptrdiff_ikind ()) x (* TODO: proper castkind *)
  let unlift x = x

  (** [rescale ~from_size ~to_size i] converts the index [i], which counts objects of [from_size] bytes,
      into an index counting objects of [to_size] bytes.
      Where the byte offset [i * from_size] is not a multiple of [to_size], it lies inside an object of [to_size] bytes,
      and the result contains the indices of the objects starting at or before it and after it,
      so that the byte offsets of the result enclose those of [i]. *)
  let rescale ~from_size ~to_size i =
    if Z.equal from_size to_size then
      i
    else
      (* Binary operations on offsets should not generate overflow warnings in SV-COMP *)
      let@ () = GobRef.wrap AnalysisState.executing_speculative_computations true in
      if Z.gt to_size Z.zero && Z.equal (Z.rem from_size to_size) Z.zero then
        mul i (of_int (Z.div from_size to_size))
      else if Z.gt to_size Z.zero then
        match minimal i, maximal i with
        | Some lo, Some hi ->
          let lo' = Z.fdiv (Z.mul lo from_size) to_size in
          let hi' = Z.cdiv (Z.mul hi from_size) to_size in
          let (min_ik, max_ik) = IntDomain.Size.range (Cilfacade.ptrdiff_ikind ()) in
          if Z.leq min_ik lo' && Z.leq hi' max_ik then
            of_interval (lo', hi')
          else
            top ()
        | _, _ -> top ()
      else
        top ()

  (** [retype ~from ~into i] converts the index [i], which counts objects of type [from], into an index counting objects of type [into],
      using {!rescale} if the two types differ in size. The result is top if the size of either type is unknown,
      except that types with the same signature count the same objects,
      and that two array types with the same element type, at least one of variable length, are assumed to have the same length. *)
  let retype ~(from: GoblintCil.typ) ~(into: GoblintCil.typ) i =
    let type_sig = GoblintCil.typeSigWithAttrs (List.filter (fun (GoblintCil.Attr (name, _)) -> name <> "arraylen")) in
    let rec contains_vla t = match GoblintCil.unrollType t with
      | TArray (_, Some len, _) when not (GoblintCil.isConstant len) -> true
      | TArray (t, _, _) -> contains_vla t
      | _ -> false
    in
    let same_sig = CilType.Typsig.equal (type_sig from) (type_sig into) in
    if same_sig && not (contains_vla from) then
      i
    else
      match Cilfacade.bytesSizeOf from, Cilfacade.bytesSizeOf into with
      | from_size, to_size -> rescale ~from_size:(Z.of_int from_size) ~to_size:(Z.of_int to_size) i
      | exception GoblintCil.SizeOfError _ ->
        let same_elements = match GoblintCil.unrollType from, GoblintCil.unrollType into with
          | TArray (from_elem, _, _), TArray (into_elem, _, _) -> CilType.Typsig.equal (type_sig from_elem) (type_sig into_elem)
          | _, _ -> false
        in
        if (contains_vla from || contains_vla into) && (same_sig || same_elements) then (
          Assumptions.add "Pointer arithmetic assumes arrays of the same element type, one of variable length, to have the same length";
          i
        )
        else
          top ()
end

module SizeDomain:
sig
  include IntDomain.ZDefault (* hide type t = ID.t, require explicit (un)lift *)
  val lift: ID.t -> t
  val unlift: t -> ID.t

  val of_index: IndexDomain.t -> t
  (** Convert an index to size, {e assuming} it is non-negative.

      This is useful for comparing an index with a size.
      A negative index check must be done separately, if needed.
      This conversion is more precise than size to index, which may overflow. *)
end =
struct
  include IntDomain.IntDomWithDefaultIkind (ID) (struct let ikind () = !GoblintCil.kindOfSizeOf end) (* TODO: add ptrdiff cast into to_int? *)
  let lift x = ID.cast_to ~kind:Internal !GoblintCil.kindOfSizeOf x (* TODO: proper castkind *)
  let unlift x = x

  let of_index index =
    let index_nonneg = IndexDomain.meet index (IndexDomain.starting Z.zero) in (* exclude negative indices *)
    lift (IndexDomain.unlift index_nonneg) (* cast in lift should never underflow *)
end

module Offs = Offset.MakeLattice (IndexDomain)
module Mval = Mval.MakeLattice (Offs)
module AD = AddressDomain.AddressSet (Mval) (ID)
module Addr =
struct
  include AD.Addr
  module Offs = Offs
  module Mval = Mval
end
