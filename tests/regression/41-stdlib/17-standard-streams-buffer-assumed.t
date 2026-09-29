The assumption is reported at the local buffer (lines 15 and 21) and the heap
buffer (line 18), not at the static buffer or at a null one.

  $ goblint 17-standard-streams-buffer-assumed.c 2>&1 | grep -F 'Assumption'
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (17-standard-streams-buffer-assumed.c:15:3-15:46)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (17-standard-streams-buffer-assumed.c:18:3-18:22)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits (17-standard-streams-buffer-assumed.c:21:5-21:43)
  [Info][Assumption] A buffer attached to a stream with setvbuf, setbuf or setbuffer stays live until the stream is closed or the program exits
