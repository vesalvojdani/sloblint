// PARAM: --set ana.malloc.wrappers "['wrap']" --set ana.malloc.unique_address_count 1
// The block of the alloca in the malloc wrapper is a stack block of its own, not the heap block the wrapper returns.
#include <alloca.h>
#include <stdlib.h>
#include <goblint.h>

void *wrap(size_t n) {
  int *s = alloca(sizeof(int));
  *s = 1;
  int *r = malloc(n);
  *r = 2;
  __goblint_check(s != r);
  __goblint_check(*s == 1);
  return r;
}

int main() {
  int *p = wrap(sizeof(int));
  __goblint_check(*p == 2);
  free(p); // NOWARN
  return 0;
}
