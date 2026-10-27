// PARAM: --enable ana.float.interval --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 2
// Branching on a read of the bytes of a double element at an integer type does not refine the element:
// the byte read is not a value of it, and the elements of the array keep their values in the branch.
// Each condition holds for the IEEE 754 format on a little-endian target.
#include <goblint.h>

int main() {
  double a[2] = {1.5, 2.5}; // 0x3ff8000000000000, 0x4004000000000000

  unsigned char *p = (unsigned char *)a;
  if (p[1] == 0) {
    __goblint_check(1); // reachable
    __goblint_check(a[0] == 1.5);
    __goblint_check(a[1] == 2.5);
  }

  unsigned char *q = (unsigned char *)a + 1;
  if (*q == 0) {
    __goblint_check(1); // reachable
    __goblint_check(a[0] == 1.5);
    __goblint_check(a[1] == 2.5);
  }

  unsigned char (*v)[16] = (unsigned char (*)[16])&a;
  if ((*v)[1] == 0) {
    __goblint_check(1); // reachable
    __goblint_check(a[0] == 1.5);
    __goblint_check(a[1] == 2.5);
  }

  __goblint_check(a[0] == 1.5);
  __goblint_check(a[1] == 2.5);
  return 0;
}
