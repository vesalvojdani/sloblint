// PARAM: --enable ana.race.direct-arithmetic
#include <pthread.h>

// The members of a union overlap, so an access through a pointer of the type of one member
// may race with an access to another member.

union IntFloat { int i; float f; };
union IntFloat int_float;

// Only accessed through unknown pointers: a short pointer and a double pointer may point into the same union.
union ShortDouble { short s; double d; };

extern int *get_int();
extern short *get_short();
extern double *get_double();

void *t_fun(void *arg) {
  int_float.f = 1; // RACE!
  *get_double() = 1; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  *get_int() = 5; // RACE!
  *get_short() = 5; // RACE!
  pthread_join(id, NULL);
  return 0;
}
