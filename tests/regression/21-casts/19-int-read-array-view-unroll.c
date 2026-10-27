// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 8
// Reading integers through a pointer to an array of another integer type, with the elements of the stored array kept apart.
// The index counts elements of the type of the view, not of the stored array.
#include <goblint.h>

int main() {
  short s[4] = {1, 2, 3, 4};
  int (*v)[2] = (int (*)[2])&s;
  int v0 = (*v)[0];
  __goblint_check(v0 == 0x20001); // UNKNOWN
  if (v0 == 0x20001)
    __goblint_check(1); // reachable
  int v1 = (*v)[1];
  __goblint_check(v1 == 0x40003); // UNKNOWN
  if (v1 == 0x40003)
    __goblint_check(1); // reachable

  int a[4] = {1, 2, 3, 4};
  long long (*l)[2] = (long long (*)[2])&a;
  long long l1 = (*l)[1];
  __goblint_check(l1 == 0x400000003LL); // UNKNOWN
  if (l1 == 0x400000003LL)
    __goblint_check(1); // reachable

  int b[2] = {0x01020304, 0x05060708};
  unsigned char (*c)[8] = (unsigned char (*)[8])&b;
  unsigned char c1 = (*c)[1];
  __goblint_check(c1 == 3); // UNKNOWN
  if (c1 == 3)
    __goblint_check(1); // reachable

  return 0;
}
