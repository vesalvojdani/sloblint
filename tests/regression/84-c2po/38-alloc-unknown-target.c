// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts --set sem.alloca.zero pointer
#include <alloca.h>
#include <stdlib.h>
#include <goblint.h>

int *unknown(int *p);

int main(void) {
  // The program allocates no block of size zero with alloca,
  // so a new allocation differs from a pointer whose target the analysis does not know.
  int x;
  int *p = unknown(&x);
  int *c = alloca(16);
  int *m = malloc(4);
  __goblint_check(m != p);
  __goblint_check(c != p);
  return 0;
}
