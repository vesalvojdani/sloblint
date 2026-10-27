// PARAM: --set ana.activated[+] uninit
// A thread created in a callee reads a local of main that escaped through a global before the call.
#include <pthread.h>

int *gp;
pthread_t id;

void *reader(void *arg) {
  int r = *gp; // WARN
  return NULL;
}

void start(void) {
  pthread_create(&id, NULL, reader, NULL);
}

int main(void) {
  int x;
  gp = &x;
  start();
  pthread_join(id, NULL);
  return 0;
}
