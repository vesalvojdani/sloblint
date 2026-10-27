// Branching on an element of a double array read through a pointer to an
// array of long long. The value read is the bytes of the double, an integer.
#include <goblint.h>

int main() {
  double a[2] = {1.5, 1.5}; // 0x3ff8000000000000 on IEEE 754 targets
  long long (*pl)[2] = (long long (*)[2])&a;
  long long l1 = (*pl)[1];
  if (l1 == 0x3ff8000000000000LL)
    __goblint_check(1); // reachable
  return 0;
}
