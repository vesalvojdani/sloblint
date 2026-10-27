// PARAM: --enable ana.float.interval
// Reading the bytes of a double and a float struct member through pointers to
// integer types reinterprets them, also at the start of the member, and
// branching on such a byte does not change the member. The values in the
// comments are those of the IEEE 754 formats on a little-endian target.
#include <goblint.h>

struct S { double d; float f; int x; };

int main() {
  struct S s = {1.5, 2.0f, 7}; // s.d is 0x3ff8000000000000, s.f is 0x40000000
  unsigned char *c = (unsigned char *)&s.d;
  unsigned char c0 = *c;
  __goblint_check(c0 == 0); // UNKNOWN
  long long *l = (long long *)&s.d;
  long long l0 = *l;
  __goblint_check(l0 == 0x3ff8000000000000LL); // UNKNOWN
  int *i = (int *)&s.f;
  int i0 = *i;
  __goblint_check(i0 == 0x40000000); // UNKNOWN

  if (c[7] == 0x3f) {
    __goblint_check(1); // reachable
    __goblint_check(s.d == 1.5);
  }
  __goblint_check(s.d == 1.5);
  __goblint_check(s.f == 2.0f);
  __goblint_check(s.x == 7);
  return 0;
}
