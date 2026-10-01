// Reads and writes through a pointer to a struct or nested struct converted to
// a pointer to its first member, which is as wide as the struct
// (C11 6.7.2.1p15).
#include <goblint.h>

struct one { long x; };
struct nest { struct one inner; };

int main() {
  struct one s = { 0 };
  long *p = (long *)&s;
  *p = 5;
  __goblint_check(s.x == 5);
  __goblint_check(*p == 5);
  s.x = 6;
  __goblint_check(*p == 6);

  struct nest n = { { 0 } };
  long *q = (long *)&n;
  *q = 3;
  __goblint_check(n.inner.x == 3);
  __goblint_check(*q == 3);

  return 0;
}
