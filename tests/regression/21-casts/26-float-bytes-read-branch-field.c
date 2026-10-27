// PARAM: --enable ana.float.interval
// Branching on a read of the bytes of a double or float struct member at an integer type does not change the member.
// Each condition holds for the IEEE 754 formats on a little-endian target.
#include <goblint.h>

struct S { double d; float f; int x; };

int main() {
  struct S s = {1.5, 2.0f, 7}; // s.d is 0x3ff8000000000000, s.f is 0x40000000

  unsigned char *c = (unsigned char *)&s.d;
  if (*c == 0)
    __goblint_check(1); // reachable
  __goblint_check(s.d == 1.5);

  int *i = (int *)&s.f;
  if (*i == 0x40000000)
    __goblint_check(1); // reachable
  __goblint_check(s.f == 2.0f);

  __goblint_check(s.d == 1.5);
  __goblint_check(s.x == 7);
  return 0;
}
