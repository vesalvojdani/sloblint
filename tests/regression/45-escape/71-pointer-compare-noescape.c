#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>

struct s { int f; };
intptr_t g;

void *t_fun(void *arg) {
  struct s *p = (struct s *)g;
  p->f = 1; // RACE!
  return NULL;
}

int main() {
  struct s a = {0};
  struct s b = {0};
  struct s *q = rand() ? &a : &b;
  void *v = &a;
  if (q == &a) // comparing addresses does not expose them
    q = NULL;
  if (v != (void *)q)
    q = NULL;
  if ((uintptr_t)q == (uintptr_t)&a) // the result of the comparison is 0 or 1
    q = NULL;
  int same = (uintptr_t)v == (uintptr_t)&a;
  g = (intptr_t)&b;
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  a.f = 2; // NORACE
  b.f = 2; // RACE!
  pthread_join(id, NULL);
  return 0;
}
