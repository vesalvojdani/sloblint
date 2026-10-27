// calloc(count, size) requests count * size bytes, which is zero when the count
// or the size is zero. With sem.malloc.zero either, the result of a request of
// zero bytes includes the null pointer, and nothing is assumed there.
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char **argv) {
  size_t n = argc - 1; // may be zero

  int *a = calloc(0, sizeof(int)); // NOWARN
  __goblint_check(a != 0); // UNKNOWN!
  int *b = calloc(4, 0); // NOWARN
  __goblint_check(b != 0); // UNKNOWN!
  int *c = calloc(n, sizeof(int)); // NOWARN
  __goblint_check(c != 0); // UNKNOWN!

  // A request of a nonzero number of bytes is assumed not to fail.
  int *d = calloc(2, sizeof(int)); // WARN (assumption: calloc does not fail)
  __goblint_check(d != 0); // holds only under the assumption

  free(a);
  free(b);
  free(c);
  free(d);
  return 0;
}
