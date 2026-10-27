// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts --enable sem.malloc.fail
#include <goblint.h>
#include <stdlib.h>

int x;

int main(int argc, char **argv) {
  // There is not enough memory for this many bytes, so each allocation returns the null pointer.
  size_t n = (size_t)1 << 62;

  int *p = malloc(n);
  int *q = malloc(n);
  __goblint_check(p != q); // UNKNOWN!

  int *c = calloc(n, 1);
  int *d = calloc(n, 1);
  __goblint_check(c != d); // UNKNOWN!

  int *r = argc > 5 ? &x : NULL;
  int *s = r;
  int *t = malloc(n);
  __goblint_check(t != s); // UNKNOWN!
  __goblint_check(t != &x);
  return 0;
}
