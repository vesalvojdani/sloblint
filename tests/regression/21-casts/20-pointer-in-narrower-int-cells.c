#include <stddef.h>
#include <stdint.h>
#include <goblint.h>

int g;

int main(void) {
  // A pointer stored over two unsigned ints: each holds half of its bytes.
  unsigned int halves[2];
  *(int **)halves = &g;
  unsigned int lo = halves[0];
  unsigned int hi = halves[1];
  // The upper half is 0 when &g is below 4 GiB (on x86-64 without PIE).
  __goblint_check(hi == 0); // UNKNOWN!
  if (hi == 0) {
    __goblint_check(1); // reachable
  }
  if (halves[1] == 0) {
    __goblint_check(1); // reachable
  }
  // The lower half gives back &g only when &g is below 4 GiB.
  int *q = (int *)(uintptr_t)lo;
  __goblint_check(q == &g); // UNKNOWN!

  // All bytes of the null pointer are 0.
  unsigned int z[2];
  *(int **)z = NULL;
  __goblint_check(z[1] == 0);

  // An integer as wide as a pointer holds all of its bytes.
  uintptr_t whole[1];
  *(int **)whole = &g;
  int *r = (int *)whole[0];
  __goblint_check(r == &g);
  return 0;
}
