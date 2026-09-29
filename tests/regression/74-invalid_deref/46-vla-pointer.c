// PARAM: --set ana.activated[+] memOutOfBounds --enable ana.int.interval
#include <stdlib.h>

// Reading through pv and pr prints base's assumption "Casting involving a VLA is assumed to work", which the test suite counts against NOWARN.
// The cram test 46-vla-pointer.t shows that those lines get no out-of-bounds warning.
int main(void) {
  int n = rand() % 3 + 1;

  // A pointer to a one-dimensional variable-length array.
  int vla[n];
  int (*pv)[n];
  pv = &vla;
  size_t s1 = sizeof(*pv);
  (*pv)[0] = 1; // NOWARN

  // A pointer to a row of a two-dimensional variable-length array.
  int vla2[n][n];
  int (*pr)[n];
  pr = &vla2[0];
  size_t s2 = sizeof(*pr);
  (*pr)[0] = 1; // NOWARN
  int x = (*pr)[0];

  (*pv)[n] = 1; // WARN
  return 0;
}
