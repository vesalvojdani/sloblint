The assumption is reported at the local buffer (lines 15 and 21), which may be
declared in a nested block since cil.addNestedScopeAttr is off, not at the
static buffer, a null one, or the heap buffer of stderr, whose free is checked.

  $ goblint 17-standard-streams-buffer-assumed.c 2>&1 | grep -F 'Assumption'
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (17-standard-streams-buffer-assumed.c:15:3-15:46)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (17-standard-streams-buffer-assumed.c:21:5-21:43)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits
