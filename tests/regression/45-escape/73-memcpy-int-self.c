// Copying a struct of integers into a global escapes the struct when one
// member holds the address of another, stored through a pointer cast.
#include <goblint.h>
#include <pthread.h>
#include <string.h>

struct s {
  unsigned long a;
  unsigned long b;
};

struct s g;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void *t_fun(void *arg) {
  unsigned long *q;
  pthread_mutex_lock(&m);
  q = *(unsigned long **)&g.a;
  pthread_mutex_unlock(&m);
  if (q)
    *q = 7; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);

  struct s l;
  *(unsigned long **)&l.a = &l.b;
  l.b = 5;
  pthread_mutex_lock(&m);
  memcpy(&g, &l, sizeof l);
  pthread_mutex_unlock(&m);
  l.b = 6; // RACE!

  pthread_mutex_lock(&m);
  pthread_mutex_unlock(&m);
  __goblint_check(l.b == 6); // UNKNOWN!

  pthread_join(id, NULL);
  return 0;
}
