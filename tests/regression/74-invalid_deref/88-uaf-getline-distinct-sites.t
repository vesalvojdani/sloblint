  $ goblint --set ana.activated[+] useAfterFree --set ana.malloc.unique_address_count 1 88-uaf-getline-distinct-sites.c 2>&1 | grep "Assumption\|UseAfterFree" | sed -r 's/sid:[0-9]+/sid:$SID/'
  [Warning][Behavior > Undefined > UseAfterFree][CWE-416] lval ((alloc@sid:$SID@tid:[main](#0))) points to a maybe freed memory region (88-uaf-getline-distinct-sites.c:18:3-18:15)
