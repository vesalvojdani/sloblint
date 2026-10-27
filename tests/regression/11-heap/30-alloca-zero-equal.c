#include <alloca.h>
#include <stdio.h>
#include <goblint.h>

int main(int argc, char **argv) {
  // A block of size zero occupies no memory, so its address may be the address of another object.
  char buf[16];
  char *c = alloca(argc - 1); // zero bytes when the program is run without arguments
  printf("%p %p\n", (void *)c, (void *)buf);
  if (c != 0) {
    __goblint_check(c != buf); // UNKNOWN!
  }

  char *a = alloca(0);
  char *b = alloca(0);
  if (a != 0 && b != 0) {
    __goblint_check(a != b); // UNKNOWN!
    if (a == b) {
      __goblint_check(1); // reachable
    }
    if (c == a || c == buf) {
      __goblint_check(1); // reachable
    }
  }

  char *d = alloca(16);
  char *e = alloca(16);
  __goblint_check(d != e);
  __goblint_check(d != buf);
  return 0;
}
