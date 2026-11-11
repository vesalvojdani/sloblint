// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 5
// calloc zeroes every element, so the elements at index 5 and above hold 0 until written.
#include <stdlib.h>
#include <goblint.h>

struct pair { int x; int y; };

int main(void) {
  int *b = calloc(50, sizeof(int));
  if (b == NULL)
    return 1;
  __goblint_check(b[40] == 0);
  b[5] = 7;
  __goblint_check(b[5] == 7); // UNKNOWN
  __goblint_check(b[6] == 0); // UNKNOWN
  __goblint_check(b[40] == 0); // UNKNOWN

  struct pair *s = calloc(20, sizeof(struct pair));
  if (s == NULL)
    return 1;
  s[8].x = 3;
  __goblint_check(s[9].x == 0); // UNKNOWN
  free(s);
  free(b);
  return 0;
}
