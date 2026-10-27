// A function without a definition may write g through the pointer in a struct passed by value without holding m, so g is not protected by m.
#include <pthread.h>
#include <goblint.h>

struct s { int *p; };
void ext(struct s a);

int g;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void *t_fun(void *arg) {
  pthread_mutex_lock(&m);
  __goblint_check(g == 0); // UNKNOWN!
  pthread_mutex_unlock(&m);
  return NULL;
}

int main() {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  struct s v;
  v.p = &g;
  ext(v);
  pthread_join(id, NULL);
  return 0;
}
