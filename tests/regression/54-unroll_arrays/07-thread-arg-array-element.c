// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 2
// Every element of an array whose first element is passed to a thread is reachable by the thread.
#include <pthread.h>
#include <goblint.h>

void *t_fun(void *arg) {
  int **ptrs = arg;
  *ptrs[1] = 42; // RACE!
  return NULL;
}

int main(void) {
  int x = 1;
  int y = 2;
  int *ptrs[2] = {&x, &y};
  pthread_t id;
  pthread_create(&id, NULL, t_fun, ptrs);
  y = 3; // RACE!
  pthread_join(id, NULL);
  return 0;
}
