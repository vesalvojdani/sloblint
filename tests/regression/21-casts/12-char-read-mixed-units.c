// Pointer arithmetic through int * and unsigned char * on the same object.
// The index of the address does not say which byte is read: c[-1] below has index 0 but reads byte 3 of a[0].
#include <stdlib.h>
#include <goblint.h>

int main() {
  int a[2] = {0x01020304, 0x01020304};
  unsigned char *c = (unsigned char *)(a + 1);
  unsigned char x = c[-1];
  __goblint_check(x == 1); // UNKNOWN
  if (x == 1)
    __goblint_check(1); // reachable

  int *p = malloc(2 * sizeof(int));
  p[0] = 0x01020304;
  p[1] = 0x01020304;
  unsigned char *d = (unsigned char *)(p + 1);
  unsigned char y = d[-1];
  __goblint_check(y == 1); // UNKNOWN
  if (y == 1)
    __goblint_check(1); // reachable

  unsigned char *e = (unsigned char *)(a + 2) - 6;
  unsigned char z = *e;
  __goblint_check(z == 2); // UNKNOWN
  if (z == 2)
    __goblint_check(1); // reachable

  free(p);
  return 0;
}
