// A struct or union passed by value to a function without a definition reaches what the pointers stored in it reach.
#include <pthread.h>

struct s { int *p; };
struct outer { int k; struct s in; };
struct indirect { struct s *sp; };
union u { long l; int *p; };
struct ints { int a; int b; };

void ext(struct s a);
void ext_outer(struct outer a);
void ext_indirect(struct indirect a);
void ext_union(union u a);
void ext_ints(struct ints a);

int g1, g2, g3, g4, g5, g6, g7;
struct s gs;

void wrap(struct s a) {
  ext(a); // RACE!
}

void *t_fun(void *arg) {
  g1 = 1; // RACE!
  g2 = 1; // RACE!
  g3 = 1; // RACE!
  g4 = 1; // RACE!
  g5 = 1; // RACE!
  g6 = 1; // RACE!
  g7 = 1; // NORACE
  return NULL;
}

int main() {
  gs.p = &g3;
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);

  struct s v1;
  v1.p = &g1;
  ext(v1); // RACE!

  struct outer v2;
  v2.k = 0;
  v2.in.p = &g2;
  ext_outer(v2); // RACE!

  struct indirect v3;
  v3.sp = &gs;
  ext_indirect(v3); // RACE!

  struct s v4;
  v4.p = &g4;
  wrap(v4);

  void (*fp)(struct s) = ext;
  struct s v5;
  v5.p = &g5;
  fp(v5); // RACE!

  union u v6;
  v6.p = &g6;
  ext_union(v6); // RACE!

  struct ints v7;
  v7.a = 1;
  v7.b = 2;
  ext_ints(v7);
  return 0;
}
