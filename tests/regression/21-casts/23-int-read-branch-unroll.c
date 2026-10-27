// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 8
// Branching on a read of an integer at another integer type does not refine the stored integer:
// the byte or bytes read are not a value of it, and the elements of the array keep their values in the branch.
#include <goblint.h>

int main() {
  int b[2] = {0x01020304, 0x05060708};
  unsigned char *p = (unsigned char *)b;
  if (p[1] == 3) {
    __goblint_check(b[0] == 0x01020304);
    __goblint_check(b[1] == 0x05060708);
  }

  int a[2] = {0x01020304, 0x05060708};
  unsigned char *q = (unsigned char *)a + 1;
  if (*q == 3) {
    __goblint_check(a[0] == 0x01020304);
    __goblint_check(a[1] == 0x05060708);
  }

  unsigned char (*c)[8] = (unsigned char (*)[8])&a;
  if ((*c)[1] == 3) {
    __goblint_check(a[0] == 0x01020304);
    __goblint_check(a[1] == 0x05060708);
  }

  short s[4] = {1, 2, 3, 4};
  int (*v)[2] = (int (*)[2])&s;
  if ((*v)[1] == 0x40003) {
    __goblint_check(s[1] == 2);
    __goblint_check(s[2] == 3);
  }

  return 0;
}
