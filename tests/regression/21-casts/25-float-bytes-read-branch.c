// PARAM: --enable ana.float.interval
// Branching directly on a read of the bytes of a double element at an integer type, which refines the pointee.
// Each condition holds for the IEEE 754 format on a little-endian target, so each guarded line is reachable.
#include <goblint.h>

int main() {
  double a[2] = {1.5, 1.5}; // 0x3ff8000000000000

  unsigned char *q = (unsigned char *)a + 7;
  if (*q == 0x3f)
    __goblint_check(1); // reachable

  unsigned char *r = (unsigned char *)a;
  if (*r == 0)
    __goblint_check(1); // reachable

  unsigned char (*v)[16] = (unsigned char (*)[16])&a;
  if ((*v)[7] == 0x3f)
    __goblint_check(1); // reachable
  if ((*v)[7] != 0x3f) {
  } else {
    __goblint_check(1); // reachable
  }

  long long *l = (long long *)a;
  if (*l == 0x3ff8000000000000LL)
    __goblint_check(1); // reachable

  __goblint_check(a[0] == 1.5);
  __goblint_check(a[1] == 1.5);
  return 0;
}
