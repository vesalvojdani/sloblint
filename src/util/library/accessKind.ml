(** Kinds of memory accesses. *)

type t =
  | Write  (** argument may be written to *)
  | Read   (** argument may be read *)
  | Free   (** argument may be freed *)
  | Call   (** argument may be called *)
  | Spawn  (** argument may be spawned *)
  | Keep   (** callee may keep a pointer to the argument's target after it returns, see {!LibraryDesc.kept} *)
[@@deriving eq, ord, hash]
(** Specifies what is known about an argument. *)

let show: t -> string = function
  | Write -> "write"
  | Read -> "read"
  | Free -> "free"
  | Call -> "call"
  | Spawn -> "spawn"
  | Keep -> "keep"

include Printable.SimpleShow (
  struct
    type nonrec t = t
    let show = show
  end
  )
