With cil.addNestedScopeAttr, only the local of the nested block is assumed to
stay live; the local of main's outermost block is reported at the return.

  $ goblint --enable cil.addNestedScopeAttr 40-standard-streams-buffer-nested-block.c 2>&1 | grep -F -e 'Assumption' -e 'as its buffer'
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (40-standard-streams-buffer-nested-block.c:11:5-11:47)
  [Warning][Behavior > Undefined > UseAfterFree][CWE-562] outer, a local of main, ends here while stdout may hold it as its buffer: a later use of stdout, or the flush and close when the program exits, can access it after its lifetime (40-standard-streams-buffer-nested-block.c:17:10-17:11)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits

Without it, any local may be declared in a nested block, so both are assumed,
and the return is still reported.

  $ goblint 40-standard-streams-buffer-nested-block.c 2>&1 | grep -F -e 'Assumption' -e 'as its buffer'
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (40-standard-streams-buffer-nested-block.c:11:5-11:47)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (40-standard-streams-buffer-nested-block.c:15:3-15:46)
  [Warning][Behavior > Undefined > UseAfterFree][CWE-562] outer, a local of main, ends here while stdout may hold it as its buffer: a later use of stdout, or the flush and close when the program exits, can access it after its lifetime (40-standard-streams-buffer-nested-block.c:17:10-17:11)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits
