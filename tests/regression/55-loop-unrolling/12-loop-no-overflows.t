Should have no overflow warning (on line 32).
The list is empty, so the loop condition is always false and the loop body is dead.

  $ goblint --enable ana.int.interval_set 12-loop-no-overflows.c
  [Warning][Deadcode] Function '__ldv_list_del' is uncalled: 3 LLoC (12-loop-no-overflows.c:16:1-19:1)
  [Warning][Deadcode] Function 'ldv_list_del' is uncalled: 2 LLoC (12-loop-no-overflows.c:21:1-23:1)
  [Warning][Deadcode] Function 'ldv_msg_free' is uncalled: 3 LLoC (12-loop-no-overflows.c:25:1-28:1)
  [Warning][Deadcode] Function 'main' has dead code:
    on lines 36..37 (12-loop-no-overflows.c:36-37)
  [Warning][Deadcode] Logical lines of code (LLoC) summary:
    live: 3
    dead: 10 (8 in uncalled functions)
    total lines: 13
  [Warning][Deadcode][CWE-570] condition '(unsigned long )(& msg->list) != (unsigned long )(& ldv_global_msg_list)' (possibly inserted by CIL) is always false (12-loop-no-overflows.c:34:346-34:384)

