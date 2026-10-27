// Reading the bytes of an int stored in malloc'd memory through unsigned char *.
// Only a read at the start of the int, on a little-endian target, is the int converted to unsigned char.
#include <stdlib.h>
#include <goblint.h>

int main() {
  int *p = malloc(sizeof(int));
  *p = 0x01020304;
  unsigned char *c = (unsigned char *)p;

  unsigned char s = *c;
  __goblint_check(s == 4);

  unsigned char c0 = c[0];
  __goblint_check(c0 == 4); // UNKNOWN

  unsigned char c1 = c[1];
  __goblint_check(c1 == 3); // UNKNOWN
  if (c1 == 3)
    __goblint_check(1); // reachable

  unsigned char c3 = c[3];
  __goblint_check(c3 == 1); // UNKNOWN
  if (c3 == 1)
    __goblint_check(1); // reachable

  // The same through the void * returned by malloc.
  void *m = malloc(sizeof(int));
  *(int *)m = 0x0100;
  unsigned char *b = m;
  unsigned char b1 = b[1];
  __goblint_check(b1 == 1); // UNKNOWN
  if (b1 == 1)
    __goblint_check(1); // reachable

  free(p);
  free(m);
  return 0;
}
