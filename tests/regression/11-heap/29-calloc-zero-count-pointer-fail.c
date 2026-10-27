// PARAM: --set sem.malloc.zero pointer --enable sem.malloc.fail
// With sem.malloc.zero pointer, calloc returns a pointer that is not null when
// its count or its size is zero; with sem.malloc.fail, it may return the null
// pointer for a nonzero number of bytes.
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char **argv) {
  size_t n = argc - 1; // may be zero

  int *a = calloc(0, sizeof(int));
  __goblint_check(a != 0);
  int *b = calloc(4, 0);
  __goblint_check(b != 0);
  int *c = calloc(n, sizeof(int));
  __goblint_check(c != 0); // UNKNOWN!
  int *d = calloc(2, sizeof(int));
  __goblint_check(d != 0); // UNKNOWN!

  free(a);
  free(b);
  free(c);
  free(d);
  return 0;
}
