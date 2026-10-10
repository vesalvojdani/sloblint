// PARAM: --set ana.activated[+] useAfterFree
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>

uintptr_t hidden;

// t frees, through a pointer whose target the pointer analysis does not know
// since arithmetic on an integer loses it, the object main allocated into p.
// main's own path frees nothing.
static void *t(void *arg) {
  free((int *) ((hidden ^ 1) ^ 1));
  return NULL;
}

int main(void) {
  int *p = malloc(sizeof(int));
  hidden = (uintptr_t) p;
  pthread_t th;
  pthread_create(&th, NULL, t, NULL);
  pthread_join(th, NULL);
  *p = 1; // WARN
  return 0;
}
