// PARAM: --enable ana.race.direct-arithmetic
#include <pthread.h>

// The bit-fields of one memory location have different types.
// A write through an int pointer may race with the write to b, which has type int,
// and with a write of the whole structure.

struct S { unsigned a : 3; int b : 5; };
struct S g;

struct T { unsigned a : 3; int b : 5; };
struct T t, u;

extern int *get_int();

void *t_fun(void *arg) {
  g.b = 1; // RACE!
  t = u; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  *get_int() = 5; // RACE!
  pthread_join(id, NULL);
  return 0;
}
