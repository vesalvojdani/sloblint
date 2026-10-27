#include <pthread.h>
#include <stdint.h>

struct s { int f; };
intptr_t g;
intptr_t h;

void *t_fun(void *arg) {
  struct s *p = (struct s *)g;
  p->f = 1; // RACE!
  struct s *q = (struct s *)h;
  q->f = 1; // RACE!
  return NULL;
}

void store(intptr_t i) {
  g = i;
}

intptr_t to_int(struct s *p) {
  return (intptr_t)p;
}

int main() {
  struct s a = {0};
  struct s b = {0};
  store((intptr_t)&a); // the conversion is an argument of a defined function
  h = to_int(&b); // the conversion is in the returned expression
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  a.f = 2; // RACE!
  b.f = 2; // RACE!
  pthread_join(id, NULL);
  return 0;
}
