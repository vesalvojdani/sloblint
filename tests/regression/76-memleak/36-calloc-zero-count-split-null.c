// PARAM: --set ana.activated[+] memLeak --set sem.malloc.zero null
// With sem.malloc.zero null, calloc with a count of zero returns only the null
// pointer, and memLeak follows only that result, as the base analysis does.
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char **argv) {
  size_t n = argc - 1; // may be zero

  int *a = calloc(0, sizeof(int)); // NOWARN
  __goblint_check(a == 0);

  int *c = calloc(n, sizeof(int)); // NOWARN
  if (c == 0) {
    __goblint_check(1); // reachable
  } else {
    __goblint_check(1); // reachable
    free(c);
  }

  __goblint_check(1); // reachable
  return 0;
}
