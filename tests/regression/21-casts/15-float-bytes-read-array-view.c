// PARAM: --enable ana.float.interval
// Reading the elements of a double array through a pointer to an array of an
// integer type reinterprets their bytes; it does not give the doubles
// converted to the integer type. The values in the comments are those of the
// IEEE 754 formats on a little-endian target.
#include <goblint.h>

int main() {
  double a[2] = {1.5, 1.5}; // 0x3ff8000000000000

  unsigned char (*pc)[16] = (unsigned char (*)[16])&a;
  unsigned char c0 = (*pc)[0];
  __goblint_check(c0 == 0); // UNKNOWN
  unsigned char c7 = (*pc)[7];
  __goblint_check(c7 == 0x3f); // UNKNOWN
  if (c7 == 0x3f)
    __goblint_check(1); // reachable

  long long (*pl)[2] = (long long (*)[2])&a;
  long long l1 = (*pl)[1];
  int low = (int)l1; // 0
  __goblint_check(low == 0); // UNKNOWN
  if (low == 0)
    __goblint_check(1); // reachable

  __goblint_check(a[1] == 1.5);
  return 0;
}
