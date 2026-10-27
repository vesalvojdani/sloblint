// A callee whose argument is a struct, union or array-containing struct passed by value
// may read and write the caller's locals that the pointers inside the argument point to.
#include <goblint.h>

struct s { int *p; };
union u { int *p; long l; };
struct arr { int *p[2]; };
struct pp { int **pp; };

int read_struct(struct s a) {
  __goblint_check(*a.p == 7);
  return *a.p;
}

void write_struct(struct s a, int c) {
  if (c)
    *a.p = 5;
}

void write_union(union u a, int c) {
  if (c)
    *a.p = 5;
}

void write_array(struct arr a, int c) {
  if (c)
    *a.p[1] = 5;
}

void write_twice_indirect(struct pp a, int c) {
  if (c)
    **a.pp = 5;
}

int main() {
  int c; // unknown

  int x = 7;
  struct s vs; vs.p = &x;
  int r = read_struct(vs);
  __goblint_check(r == 7);
  write_struct(vs, c);
  __goblint_check(x == 5); // UNKNOWN!
  __goblint_check(x == 7); // UNKNOWN!

  int y = 7;
  union u vu; vu.p = &y;
  write_union(vu, c);
  __goblint_check(y == 5); // UNKNOWN!
  __goblint_check(y == 7); // UNKNOWN!

  int z0 = 7, z1 = 7;
  struct arr va; va.p[0] = &z0; va.p[1] = &z1;
  write_array(va, c);
  __goblint_check(z0 == 7); // UNKNOWN (the elements of va.p are joined, so the write may go to z0)
  __goblint_check(z1 == 5); // UNKNOWN!
  __goblint_check(z1 == 7); // UNKNOWN!

  int w = 7;
  int *pw = &w;
  struct pp vp; vp.pp = &pw;
  write_twice_indirect(vp, c);
  __goblint_check(w == 5); // UNKNOWN!
  __goblint_check(w == 7); // UNKNOWN!
  return 0;
}
