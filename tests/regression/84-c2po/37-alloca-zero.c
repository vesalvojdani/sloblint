// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts --set sem.alloca.zero pointer
#include <alloca.h>
#include <stdio.h>
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char **argv) {
  // A block of size zero occupies no memory, so its address may be the address of another block.
  size_t n = argc > 5 ? 4 : 0;
  int *a = alloca(n);
  int *b = alloca(n);
  __goblint_check(a != b); // UNKNOWN!

  int *e = alloca(16);
  printf("%p %p\n", (void *)a, (void *)e);
  __goblint_check(a != e); // UNKNOWN!

  int *c = alloca(4);
  int *d = alloca(4);
  __goblint_check(c != d);
  return 0;
}
