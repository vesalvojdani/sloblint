// PARAM: --set ana.activated[+] memLeak
// memLeak follows the null pointer returned by calloc where the base analysis
// includes it: with sem.malloc.zero either, when the count or the size may be zero.
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char **argv) {
  size_t n = argc - 1; // may be zero

  int *a = calloc(0, sizeof(int)); // NOWARN
  if (a == 0) {
    __goblint_check(1); // reachable
  } else {
    free(a);
  }

  int *c = calloc(n, sizeof(int)); // NOWARN
  if (c == 0) {
    __goblint_check(1); // reachable
  } else {
    free(c);
  }

  int *d = calloc(2, sizeof(int)); // WARN (assumption: calloc does not fail)
  if (d == 0) {
    __goblint_check(0); // NOWARN (unreachable under the assumption)
    return 1;
  }
  free(d);
  return 0;
}
