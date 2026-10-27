  $ goblint --set ana.activated[+] useAfterFree 18-simple-uaf.c 2>&1 | sed -r 's/sid:[0-9]+/sid:$SID/'
  [Info][Assumption] Heap allocation does not fail: functions that allocate on the heap, such as malloc, calloc and realloc, return the null pointer only when the number of bytes requested is zero (18-simple-uaf.c:6:9-6:35)
  [Warning][Behavior > Undefined > UseAfterFree][CWE-416] lval ((alloc@sid:$SID@tid:[main])) points to a maybe freed memory region (18-simple-uaf.c:11:5-11:14)
  [Warning][Behavior > Undefined > DoubleFree][CWE-415] lval ((alloc@sid:$SID@tid:[main])) points to a maybe freed memory region (18-simple-uaf.c:12:5-12:14)
  [Info][Deadcode] Logical lines of code (LLoC) summary:
    live: 7
    dead: 0
    total lines: 7
  [Info][Assumption] Heap allocation does not fail: functions that allocate on the heap, such as malloc, calloc and realloc, return the null pointer only when the number of bytes requested is zero
