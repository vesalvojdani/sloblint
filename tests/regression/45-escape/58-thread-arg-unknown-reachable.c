#include <pthread.h>
#include <stdlib.h>
#include <goblint.h>

void *t_fun(void *arg) {
  int *q = arg;
  *q = 1; // RACE!
  return NULL;
}

int main() {
  int a[2] = {0, 0};
  int *p = rand() ? a : NULL;

  pthread_t id;
  pthread_create(&id, NULL, t_fun, p + 1); // a + 1, or NULL + 1, which is the unknown pointer: a escapes
  __goblint_check(a[1] == 0); // UNKNOWN!
  a[1] = 2; // RACE!
  return 0;
}
