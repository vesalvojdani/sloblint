#include <pthread.h>
#include <stdlib.h>
#include <goblint.h>

int *arr[2];

void *t_fun(void *arg) {
  int *p = arr[1];
  if (p != NULL)
    *p = 1; // RACE!
  return NULL;
}

int main() {
  int x = 0;
  int **q = rand() ? arr : NULL;
  q = q + 1; // &arr[1], or NULL + 1, which is the unknown pointer
  *q = &x; // may write to the global arr[1]: x escapes

  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  __goblint_check(x == 0); // UNKNOWN!
  x = 2; // RACE!
  return 0;
}
