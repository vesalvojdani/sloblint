// PARAM: --disable warn.imprecise --enable cil.addNestedScopeAttr --set ana.activated[+] threadJoins
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

// 32-standard-streams-buffer-main-local-threads.c where the worker may call
// main: a frame of main may then be on the worker's stack, so its
// pthread_exit may end main's buffer.

int main(int argc, char **argv);

static void *worker(void *arg) {
  if (arg)
    main(0, NULL);
  pthread_exit(NULL); // WARN
}

int main(int argc, char **argv) {
  char buffer[BUFSIZ];
  setvbuf(stdout, buffer, _IOFBF, sizeof buffer); // NOWARN
  pthread_t t;
  pthread_create(&t, NULL, worker, NULL);
  pthread_join(t, NULL);
  exit(0); // NOWARN
}
