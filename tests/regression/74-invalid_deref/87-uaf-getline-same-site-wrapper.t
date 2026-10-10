  $ goblint --set ana.activated[+] useAfterFree 87-uaf-getline-same-site-wrapper.c 2>&1 | grep "Assumption\|UseAfterFree"
  [Info][Assumption] getline is assumed not to free a block allocated at the same site as the object its argument points to (useAfterFree) (87-uaf-getline-same-site-wrapper.c:22:7-22:41)
  [Info][Assumption] getline is assumed not to free a block allocated at the same site as the object its argument points to (useAfterFree)
