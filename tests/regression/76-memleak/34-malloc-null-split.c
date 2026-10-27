// PARAM: --set ana.activated[+] memLeak
// memLeak follows the null pointer returned by an allocation exactly where
// the base analysis includes it in the result.
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char **argv) {
  size_t n = argc - 1; // may be zero

  // With sem.malloc.zero either, an allocation of zero bytes may return NULL.
  int *m = malloc(n); // NOWARN
  if (m == 0) {
    __goblint_check(1); // reachable
  } else {
    free(m);
  }

  int *z = malloc(0); // NOWARN
  if (z == 0) {
    __goblint_check(1); // reachable
  } else {
    free(z);
  }

  // Without sem.malloc.fail, a nonzero allocation is assumed not to fail.
  int *p = malloc(sizeof(int)); // WARN (assumption: malloc does not fail)
  if (p == 0) {
    __goblint_check(0); // NOWARN (unreachable under the assumption)
    return 1;
  }
  free(p);
  return 0;
}
