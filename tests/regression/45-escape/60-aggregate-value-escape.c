// Locals escape through pointers stored in struct, union and array values that
// are assigned to globals.
#include <pthread.h>
#include <unistd.h>
#include <goblint.h>

struct s { int *p; };
union u { long l; int *p; };
struct a { int n; int *ps[4]; };

struct s g1, g2;
union u g3;
struct a g4;

struct s wrap(int *p) {
  struct s r;
  r.p = p;
  return r;
}

void *t_fun(void *arg) {
  *g1.p = 1; // RACE!
  *g2.p = 1; // RACE!
  *g3.p = 1; // RACE!
  *g4.ps[3] = 1; // RACE!
  return NULL;
}

int main() {
  int x1 = 0, x2 = 0, x3 = 0, x4 = 0, y = 0;
  struct s v1;
  union u v3;
  struct a v4;
  v1.p = &x1;
  v3.p = &x3;
  v4.n = 0;
  v4.ps[0] = &y;
  v4.ps[1] = &y;
  v4.ps[2] = &y;
  v4.ps[3] = &x4;

  g1 = v1; // struct
  g2 = wrap(&x2); // struct returned by value
  g3 = v3; // union
  g4 = v4; // array of pointers in a struct

  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  sleep(1);
  __goblint_check(x1 == 0); // UNKNOWN!
  __goblint_check(x2 == 0); // UNKNOWN!
  __goblint_check(x3 == 0); // UNKNOWN!
  __goblint_check(x4 == 0); // UNKNOWN!
  pthread_join(id, NULL);
  return 0;
}
