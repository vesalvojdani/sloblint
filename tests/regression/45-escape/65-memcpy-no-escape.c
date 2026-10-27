// Copying from a local that holds no address into a global, or from a local
// holding an address into a local that has not escaped, escapes nothing.
#include <goblint.h>
#include <pthread.h>
#include <string.h>

struct pair {
  int a;
  int b;
};

struct pair g;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void *t_fun(void *arg) {
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);

  struct pair l = { 1, 2 };
  memcpy(&g, &l, sizeof l);
  l.a = 3; // NORACE

  int x = 5;
  int *p = &x;
  int *q;
  memcpy(&q, &p, sizeof p);
  *q = 6; // NORACE

  // An escaped local would lose its value here.
  pthread_mutex_lock(&m);
  pthread_mutex_unlock(&m);
  __goblint_check(l.a == 3);
  __goblint_check(x == 6);

  pthread_join(id, NULL);
  return 0;
}
