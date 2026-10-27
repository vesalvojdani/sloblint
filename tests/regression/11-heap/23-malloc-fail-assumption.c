// Without sem.malloc.fail, the analysis leaves out the null pointer that a failing
// heap allocation returns, and declares this assumption at each call that relies on it.
#include <stdlib.h>
#include <alloca.h>
#include <goblint.h>

int main(int argc, char **argv) {
  size_t n = argc - 1; // may be zero

  int *p = malloc(sizeof(int)); // WARN (assumption: malloc does not fail)
  __goblint_check(p != 0); // holds only under the assumption

  int *q = calloc(4, sizeof(int)); // WARN (assumption: calloc does not fail)
  __goblint_check(q != 0); // holds only under the assumption

  int *r = realloc(p, 8 * sizeof(int)); // WARN (assumption: realloc does not fail)
  __goblint_check(r != 0); // holds only under the assumption

  // With sem.malloc.zero either, the result includes the null pointer for a size
  // that may be zero, so nothing is assumed.
  int *z = malloc(0); // NOWARN
  __goblint_check(z != 0); // UNKNOWN!
  int *m = malloc(n); // NOWARN
  __goblint_check(m != 0); // UNKNOWN!

  // alloca does not return the null pointer when it fails.
  char *a = alloca(4); // NOWARN
  __goblint_check(a != 0);

  free(q);
  free(r);
  free(z);
  free(m);
  return 0;
}
