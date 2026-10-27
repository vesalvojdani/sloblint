  $ goblint --set ana.activated[+] useAfterFree 85-uaf-library-frees-unknown-address.c 2>&1 | grep Assumption
  [Info][Assumption] Memory that closedir frees through an unknown pointer is assumed not to be accessed afterwards (useAfterFree) (85-uaf-library-frees-unknown-address.c:14:3-14:14)
  [Info][Assumption] Memory that freeaddrinfo frees through an unknown pointer is assumed not to be accessed afterwards (useAfterFree) (85-uaf-library-frees-unknown-address.c:19:3-19:20)
  [Info][Assumption] Memory that closedir frees through an unknown pointer is assumed not to be accessed afterwards (useAfterFree)
  [Info][Assumption] Memory that freeaddrinfo frees through an unknown pointer is assumed not to be accessed afterwards (useAfterFree)
