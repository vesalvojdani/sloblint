// A struct passed by value carries a pointer to a local of main to a function that starts a thread with it.
#include <pthread.h>
#include <goblint.h>

struct s { int *p; };

void *t_fun(void *arg) {
  int *q = arg;
  *q = 1; // RACE!
  return NULL;
}

pthread_t id;

void spawn(struct s a) {
  pthread_create(&id, NULL, t_fun, a.p);
}

int main() {
  int x = 0;
  struct s v;
  v.p = &x;
  spawn(v);
  int r = x; // RACE!
  __goblint_check(r == 0); // UNKNOWN!
  __goblint_check(r == 1); // UNKNOWN!
  pthread_join(id, NULL);
  return 0;
}
