// Writes through a pointer read from the first member of a struct, union or
// array whose address was converted to a pointer to that member's type
// (C11 6.7.2.1p15-16, 6.3.2.3p7). The member is as wide as its container.
#include <goblint.h>

struct box { int *slot; };
struct outer { struct box inner; };
union either { int *p; long l; };
union other { long l; int *p; };

int main() {
  int c = 0;

  // via void *
  struct box b = { &c };
  void *payload = &b;
  int **slot = payload;
  **slot = 1;
  __goblint_check(c == 1);

  // direct cast
  **(int **)&b = 2;
  __goblint_check(c == 2);

  // nested struct
  struct outer o = { { &c } };
  **(int **)&o = 3;
  __goblint_check(c == 3);

  // array
  int *a[1] = { &c };
  **(int **)&a = 4;
  __goblint_check(c == 4);

  // union, first member
  union either u;
  u.p = &c;
  **(int **)&u = 5;
  __goblint_check(c == 5);

  // union, later member: the cast still keeps the union's own offset
  union other w;
  w.p = &c;
  **(int **)&w = 6;
  __goblint_check(c == 6); // TODO

  return 0;
}
