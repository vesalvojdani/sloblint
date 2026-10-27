// PARAM: --set ana.malloc.unique_address_count 1
// Each iteration's alloca allocates a new block, so the block of the second iteration differs from the first.
#include <alloca.h>
#include <goblint.h>

int main() {
  int *p[2];
  for (int i = 0; i < 2; i++) {
    p[i] = alloca(sizeof(int));
  }
  int *a = p[0];
  int *b = p[1];
  __goblint_check(a != b); // UNKNOWN

  *a = 1;
  *b = 2;
  __goblint_check(*a == 1); // UNKNOWN
  __goblint_check(*b == 2); // UNKNOWN
  return 0;
}
