// PARAM: --set sem.malloc.zero null
// With sem.malloc.zero null, calloc returns the null pointer when its count or
// its size is zero.
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char **argv) {
  size_t n = argc - 1; // may be zero

  int *a = calloc(0, sizeof(int)); // NOWARN
  __goblint_check(a == 0);
  int *b = calloc(4, 0); // NOWARN
  __goblint_check(b == 0);
  int *c = calloc(n, sizeof(int)); // NOWARN
  __goblint_check(c != 0); // UNKNOWN!

  int *d = calloc(2, sizeof(int)); // WARN (assumption: calloc does not fail)
  __goblint_check(d != 0); // holds only under the assumption

  free(c);
  free(d);
  return 0;
}
