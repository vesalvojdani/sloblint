// A pointer to a local copied into an integer with memcpy, and from the
// integer into a global, makes the local escape.
#include <pthread.h>
#include <stdint.h>
#include <string.h>

struct s { int f; };

uintptr_t gi;
struct s *gp;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void *t_fun(void *arg) {
  uintptr_t i;
  struct s *p, *q;
  pthread_mutex_lock(&m);
  i = gi;
  q = gp;
  pthread_mutex_unlock(&m);
  memcpy(&p, &i, sizeof p);
  if (p)
    p->f = 1; // RACE!
  if (q)
    q->f = 1; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);

  struct s a = {0};
  struct s b = {0};
  struct s *pa = &a;
  struct s *pb = &b;
  uintptr_t ia, ib;
  memcpy(&ia, &pa, sizeof ia);
  memcpy(&ib, &pb, sizeof ib);
  pthread_mutex_lock(&m);
  gi = ia; // the integer holding the address of a is stored in a global
  gp = (struct s *)ib; // the integer holding the address of b is converted back and stored in a global
  pthread_mutex_unlock(&m);
  a.f = 2; // RACE!
  b.f = 2; // RACE!

  pthread_join(id, NULL);
  return 0;
}
