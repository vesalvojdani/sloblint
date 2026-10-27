// Copying a struct holding a pointer to a local into a global with memmove,
// after a thread has been created, escapes the local.
#include <pthread.h>
#include <string.h>

struct s {
  int n;
  int *p;
};

struct s g;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void *t_fun(void *arg) {
  int *q;
  pthread_mutex_lock(&m);
  q = g.p;
  pthread_mutex_unlock(&m);
  if (q)
    *q = 7; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);

  int x = 5;
  struct s l = { 1, &x };
  pthread_mutex_lock(&m);
  memmove(&g, &l, sizeof l);
  pthread_mutex_unlock(&m);
  x = 6; // RACE!

  pthread_join(id, NULL);
  return 0;
}
