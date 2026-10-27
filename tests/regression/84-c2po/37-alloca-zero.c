// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts --set sem.alloca.zero pointer
#include <alloca.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <goblint.h>

// A block of size zero occupies no memory, so its address may be the address of another block.

void unknown_target(size_t n, int argc) {
  int *z = alloca(n);
  uintptr_t u = (uintptr_t)z;
  int *p = (int *)(u * (uintptr_t)(argc > 0)); // p is z, but the analysis does not know what p points to
  int *q = p;
  int *f = alloca(16);
  printf("%p %p\n", (void *)p, (void *)f);
  __goblint_check(f != p); // UNKNOWN!
  __goblint_check(f != q); // UNKNOWN!
}

int main(int argc, char **argv) {
  size_t n = argc > 5 ? 4 : 0;
  int *a = alloca(n);
  int *b = alloca(n);
  __goblint_check(a != b); // UNKNOWN!

  int *e = alloca(16);
  printf("%p %p\n", (void *)a, (void *)e);
  __goblint_check(a != e); // UNKNOWN!

  unknown_target(n, argc);

  int *c = alloca(4);
  int *d = alloca(4);
  __goblint_check(c != d);
  return 0;
}
