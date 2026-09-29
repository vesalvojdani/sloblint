  $ goblint --set ana.activated[+] memOutOfBounds --enable ana.int.interval 46-vla-pointer.c
  [Warning] The memOutOfBounds analysis enables cil.addNestedScopeAttr.
  [Info][Assumption] Casting involving a VLA is assumed to work (46-vla-pointer.c:13:10-13:26)
  [Info][Assumption] Casting involving a VLA is assumed to work (46-vla-pointer.c:20:10-20:26)
  [Info][Assumption] Casting involving a VLA is assumed to work (46-vla-pointer.c:22:7-22:19)
  [Warning][Behavior > Undefined > MemoryOutOfBoundsAccess][CWE-823] Could not compare size of lval dereference expression ((Unknown int([-63,63]),[4,12])) (in bytes) with offset by (⊤) (in bytes). Memory out-of-bounds access might occur (46-vla-pointer.c:24:4-24:15)
  [Info][Deadcode] Logical lines of code (LLoC) summary:
    live: 15
    dead: 0
    total lines: 15
  [Info][Assumption] Casting involving a VLA is assumed to work
