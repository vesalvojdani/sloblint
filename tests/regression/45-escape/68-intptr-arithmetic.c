// PARAM: --enable ana.race.direct-arithmetic
#include <pthread.h>
#include <stdint.h>

intptr_t g;

void *t_fun(void *arg) {
  int *p = (int *)g;
  *p = 1; // RACE!
  return NULL;
}

int main() {
  int x = 0;
  g = (intptr_t)&x;
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  x = 2; // RACE!
  pthread_join(id, NULL);
  return 0;
}
