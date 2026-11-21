// Branching directly on a read of an integer at another integer type, which refines the pointee.
// Each condition holds on a little-endian target, so each guarded line is reachable.
#include <stdlib.h>
#include <goblint.h>

int main() {
  int a[2] = {0x01020304, 0x01020304};

  unsigned char *q = (unsigned char *)a + 1;
  if (*q == 3)
    __goblint_check(1); // reachable

  unsigned char *r = (unsigned char *)(a + 1) - 3;
  if (*r == 3)
    __goblint_check(1); // reachable

  int *p = malloc(sizeof(int));
  *p = 0x01020304;
  unsigned char *m = (unsigned char *)p + 1;
  if (*m == 3)
    __goblint_check(1); // reachable

  unsigned char (*c)[8] = (unsigned char (*)[8])&a;
  if ((*c)[1] == 3)
    __goblint_check(1); // reachable
  if ((*c)[1] != 3) {
  } else {
    __goblint_check(1); // reachable
  }

  short s[4] = {1, 1, 1, 1};
  int (*v)[2] = (int (*)[2])&s;
  if ((*v)[1] == 0x10001)
    __goblint_check(1); // reachable

  free(p);
  return 0;
}
