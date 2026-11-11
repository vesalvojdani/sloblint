#include <pthread.h>
#include <stdlib.h>
#include <goblint.h>

int *g;

void *t_fun(void *arg) {
  *g = 1; // RACE!
  return NULL;
}

int main() {
  int a[2] = {0, 0};
  int *p = rand() ? a : NULL;
  g = p + 1; // a + 1, or NULL + 1, which is the unknown pointer: a escapes

  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  __goblint_check(a[1] == 0); // UNKNOWN!
  a[1] = 2; // RACE!
  return 0;
}
