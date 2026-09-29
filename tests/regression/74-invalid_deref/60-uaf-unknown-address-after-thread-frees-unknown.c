// PARAM: --set ana.activated[+] useAfterFree --disable warn.info
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>

uintptr_t hidden;

// t frees the object whose address hidden holds, through a pointer whose
// target the pointer analysis does not know since arithmetic on an integer
// loses it, and main then uses it the same way.
static void *t(void *arg) {
  free((int *) ((hidden ^ 1) ^ 1));
  return NULL;
}

int main(void) {
  hidden = (uintptr_t) malloc(sizeof(int));
  pthread_t th;
  pthread_create(&th, NULL, t, NULL);
  pthread_join(th, NULL);
  int *p = (int *) ((hidden ^ 1) ^ 1);
  if (p == NULL)
    return 1;
  return *p; // WARN
}
