// A local whose address Base keeps in an integer object escapes when the
// integer is stored in a global.
#include <pthread.h>
#include <stdint.h>

struct s { int f; };

uintptr_t g;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void *t_fun(void *arg) {
  uintptr_t i;
  pthread_mutex_lock(&m);
  i = g;
  pthread_mutex_unlock(&m);
  struct s *p = (struct s *)i;
  if (p)
    p->f = 1; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);

  struct s a = {0};
  uintptr_t i;
  *(struct s **)&i = &a; // Base keeps the address of a in the integer i
  pthread_mutex_lock(&m);
  g = i;
  pthread_mutex_unlock(&m);
  a.f = 2; // RACE!

  pthread_join(id, NULL);
  return 0;
}
