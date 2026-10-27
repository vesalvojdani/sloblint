#include <pthread.h>

// Both members of the union have type struct A.
// The race between the two writes through struct A pointers is reported at (struct A).x only,
// not again at the second member of (union AA).

struct A { int x; };
union AA { struct A a1; struct A a2; };
union AA u;

extern struct A *get_a();

void *t_fun(void *arg) {
  get_a()->x = 1; // RACE!
  u.a1.x = 1; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  get_a()->x = 2; // RACE!
  u.a2.x = 2; // RACE!
  pthread_join(id, NULL);
  return 0;
}
