// PARAM: --disable warn.imprecise --enable cil.addNestedScopeAttr --set ana.activated[+] threadJoins
#include <stdio.h>
#include <pthread.h>

// pthread_exit ends every frame on the exiting thread's stack, not only the
// current function's: a buffer attached to a stream in any of them ends while
// the stream holds it, and main's flush reads it after its lifetime.

static void *exits_in_start_routine(void *arg) {
  char buffer[BUFSIZ];
  setvbuf(stdout, buffer, _IOFBF, sizeof buffer); // NOWARN
  fputs("a", stdout);
  pthread_exit(NULL); // WARN
}

static void quit(void) {
  pthread_exit(NULL); // WARN (ends the caller's frame as well)
}

static void *exits_in_callee(void *arg) {
  char buffer[BUFSIZ];
  setvbuf(stderr, buffer, _IOFBF, sizeof buffer); // NOWARN
  fputs("b", stderr);
  quit();
  return NULL;
}

int main(void) {
  pthread_t t1, t2;
  pthread_create(&t1, NULL, exits_in_start_routine, NULL);
  pthread_join(t1, NULL);
  pthread_create(&t2, NULL, exits_in_callee, NULL);
  pthread_join(t2, NULL);
  fflush(NULL);
  return 0;
}
