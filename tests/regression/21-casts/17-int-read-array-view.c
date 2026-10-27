// Reading the bytes of integers through a pointer to an array of a narrower integer type.
// The index counts elements of the narrower type, so (*c)[1] is the second byte of a[0], not a[1] converted to unsigned char.
#include <goblint.h>

int main() {
  int a[2] = {0x01020304, 0x01020304};

  unsigned char (*c)[8] = (unsigned char (*)[8])&a;
  unsigned char c0 = (*c)[0];
  __goblint_check(c0 == 4); // UNKNOWN
  unsigned char c1 = (*c)[1];
  __goblint_check(c1 == 3); // UNKNOWN
  if (c1 == 3)
    __goblint_check(1); // reachable

  short (*s)[4] = (short (*)[4])&a;
  short s1 = (*s)[1];
  __goblint_check(s1 == 0x0102); // UNKNOWN
  if (s1 == 0x0102)
    __goblint_check(1); // reachable

  long long l[1] = {0x0102030405060708LL};
  int (*i)[2] = (int (*)[2])&l;
  int i1 = (*i)[1];
  __goblint_check(i1 == 0x01020304); // UNKNOWN
  if (i1 == 0x01020304)
    __goblint_check(1); // reachable

  return 0;
}
