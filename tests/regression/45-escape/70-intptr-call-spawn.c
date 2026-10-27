#include <pthread.h>
#include <stdint.h>

struct s { int f; };
intptr_t g;
pthread_t id;

void *t_fun(void *arg) {
  struct s *p = (struct s *)g;
  p->f = 1; // RACE!
  return NULL;
}

void store_and_spawn(intptr_t i) {
  g = i;
  pthread_create(&id, NULL, t_fun, NULL);
}

int main() {
  struct s a = {0};
  store_and_spawn((intptr_t)&a); // the program becomes multithreaded in the callee
  a.f = 2; // RACE!
  pthread_join(id, NULL);
  return 0;
}
