// PARAM: --disable warn.imprecise --enable cil.addNestedScopeAttr
#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>

// Under deferred cancellation, the default, a thread acts on a cancellation
// request only at a later cancellation point, here pthread_testcancel, so
// main's frame may end with a buffer attached after the request. A cancelled
// thread's frames end without a return or a pthread_exit, which the analysis
// does not check, so wherever the program may cancel a thread, a local handed
// to a stream is assumed to stay live.
int main(void) {
  char buffer[BUFSIZ];
  pthread_cancel(pthread_self()); // NOWARN
  setvbuf(stdout, buffer, _IOFBF, sizeof buffer); // WARN (assumption)
  fputs("hello", stdout);
  pthread_testcancel();
  exit(0);
}
