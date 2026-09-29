main hands stdout its local buffer and returns, so the buffer ends before exit
flushes stdout: a default run reports it at the return, as CWE-562.

  $ goblint 27-standard-streams-buffer-main-return.c 2>&1 | grep -F 'as its buffer'
  [Warning][Behavior > Undefined > UseAfterFree][CWE-562] buffer, a local of main, ends here while stdout may hold it as its buffer: a later use of stdout, or the flush and close when the program exits, can access it after its lifetime (27-standard-streams-buffer-main-return.c:10:10-10:11)
