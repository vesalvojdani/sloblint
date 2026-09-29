// PARAM: --disable warn.imprecise --enable cil.addNestedScopeAttr --set ana.activated[+] threadJoins
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

// main gives stdout a buffer of its own for the whole run. A thread other than
// the main one has no frame of main on its stack, since the program neither
// calls main nor takes its address, so a worker's pthread_exit does not end
// main's buffer.

static void *worker(void *arg) {
  puts("worker");
  pthread_exit(NULL); // NOWARN
}

int main(void) {
  char buffer[BUFSIZ];
  setvbuf(stdout, buffer, _IOFBF, sizeof buffer); // NOWARN
  pthread_t t;
  pthread_create(&t, NULL, worker, NULL);
  pthread_join(t, NULL);
  puts("main");
  exit(0); // NOWARN (exit flushes before main's frame ends)
}
