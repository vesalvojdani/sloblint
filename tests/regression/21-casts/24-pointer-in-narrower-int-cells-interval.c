// PARAM: --enable ana.int.interval
#include <goblint.h>

int g;

int main(void) {
  // Reading half of a pointer is not a conversion in the program, so it cannot overflow.
  unsigned int halves[2];
  *(int **)halves = &g;
  unsigned int lo = halves[0]; // NOWARN
  unsigned int hi = halves[1]; // NOWARN
  if (hi == 0) {
    __goblint_check(1); // reachable when &g is below 4 GiB
  }

  int signed_halves[2];
  *(int **)signed_halves = &g;
  int shi = signed_halves[1]; // NOWARN
  if (shi == 0) {
    __goblint_check(1); // reachable when &g is below 4 GiB
  }
  if (signed_halves[0] < 0) { // NOWARN
    __goblint_check(1); // reachable when bit 31 of &g is set
  }
  return 0;
}
