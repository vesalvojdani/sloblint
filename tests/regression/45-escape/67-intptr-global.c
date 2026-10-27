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

int main() {
  struct s a = {0};
  struct s b = {0};
  g = (intptr_t)&a; // a escapes: t_fun converts g back to a pointer to it
  intptr_t i = (intptr_t)&b; // b escapes, although the integer is first stored in a local
  h = i;
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  a.f = 2; // RACE!
  b.f = 2; // RACE!
  pthread_join(id, NULL);
  return 0;
}
