// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts
#include <goblint.h>
#include <stdlib.h>
#include <alloca.h>

int main(int argc, char **argv) {
  // With sem.malloc.zero and sem.alloca.zero set to either, an allocation of zero bytes may return the null pointer.
  size_t n = argc > 5 ? 4 : 0;

  int *p = malloc(n);
  int *q = malloc(n);
  __goblint_check(p != q); // UNKNOWN!

  int *c = calloc(4, n);
  int *d = calloc(4, n);
  __goblint_check(c != d); // UNKNOWN!

  int *a = alloca(n);
  int *b = alloca(n);
  __goblint_check(a != b); // UNKNOWN!
  return 0;
}
