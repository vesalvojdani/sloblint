// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 2
// An unknown function given a pointer to an array element may write every element of the array
// and everything the elements point to.
#include <goblint.h>

void unknown(int **p);

int main(void) {
  int x = 1;
  int y = 2;
  int *ptrs[2] = {&x, &y};
  unknown(ptrs);
  __goblint_check(ptrs[1] == &y); // UNKNOWN!
  __goblint_check(y == 2); // UNKNOWN!

  int z = 3;
  int *qtrs[2] = {&x, &z};
  int **q = &qtrs[0];
  unknown(&q); // q points to an element of qtrs, so z is reachable through qtrs[1]
  __goblint_check(z == 3); // UNKNOWN!
  return 0;
}
