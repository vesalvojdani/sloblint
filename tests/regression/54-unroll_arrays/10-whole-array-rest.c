// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 5
// memset and memcpy given a pointer to a whole array write every element, including those at index 5 and above.
// Goblint models this memcpy as writing unknown values (its source has another type), so c[8] == 1 is not provable.
#include <string.h>
#include <goblint.h>

int src[10] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

int main(void) {
  int a[10];
  for (int i = 0; i < 10; i++)
    a[i] = 5;
  memset(&a, 0, sizeof a);
  a[7] = 3;
  __goblint_check(a[8] == 0); // UNKNOWN
  __goblint_check(a[8] == 3); // UNKNOWN

  int c[10];
  for (int i = 0; i < 10; i++)
    c[i] = 5;
  memcpy(&c, src, sizeof c);
  c[7] = 3;
  __goblint_check(c[8] == 1); // UNKNOWN
  __goblint_check(c[8] == 3); // UNKNOWN
  return 0;
}
