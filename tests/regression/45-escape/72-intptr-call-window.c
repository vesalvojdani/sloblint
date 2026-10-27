#include <pthread.h>
#include <stdint.h>

struct s { int f; };
intptr_t g;
pthread_t id;

void *t_fun(void *arg) {
  struct s *p = (struct s *)g;
  p->f = 1; // TODO RACE!
  return NULL;
}

void f(intptr_t i, struct s *q) {
  g = i;
  pthread_create(&id, NULL, t_fun, NULL);
  q->f = 2; // TODO RACE! (the address that the argument i exposes escapes only when f returns)
  pthread_join(id, NULL);
}

int main() {
  struct s a = {0};
  f((intptr_t)&a, &a);
  return 0;
}
