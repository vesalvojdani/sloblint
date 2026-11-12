// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 2 --enable ana.int.congruence --enable ana.int.enums
// Accesses through character pointers moved by pointer arithmetic to the start of, or into, a wider member or element.
#include <goblint.h>

struct B { unsigned a : 3; unsigned b : 5; int c; };
struct S { int x; int y; };
union U { char c[8]; int i[2]; };

int main() {
  // Four bytes into the struct is the start of c, past the bit-fields.
  struct B sb = {1, 2, 3};
  char *pb = (char *)&sb + 4;
  __goblint_check(*(int *)pb == 3);

  // Writing one byte of an int leaves its other bytes.
  struct S s = {0, 0x100};
  ((char *)&s)[4] = 1;
  __goblint_check(s.y == 1); // UNKNOWN
  __goblint_check(s.x == 0);

  int a[2] = {0x100, 0x100};
  ((char *)a)[4] = 1;
  __goblint_check(a[1] == 1); // UNKNOWN
  __goblint_check(a[0] == 0x100);

  int x = 0x100;
  *(char *)&x = 1;
  __goblint_check(x == 1); // UNKNOWN

  // One int before s.y is s.x.
  int *py = &s.y;
  s.x = 7;
  __goblint_check(*(py - 1) == 7);

  // Byte 1 of u is inside u.i[0]; the index of the element containing it does not make the two pointers different.
  union U u;
  char *p = (char *)&u.i[0] + 1;
  char *q = u.c + 1;
  int r = 0;
  if (p == q)
    r = 1;
  __goblint_check(r == 1); // UNKNOWN

  return 0;
}
