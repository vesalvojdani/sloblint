// Reading the bytes of an element of an int array through unsigned char *.
// c[1] is the second byte of a[0], not a[1] converted to unsigned char.
#include <goblint.h>

int main() {
  int a[2] = {0x0102, 0x0102};
  unsigned char *c = (unsigned char *)a;

  unsigned char c0 = c[0];
  __goblint_check(c0 == 2); // UNKNOWN

  unsigned char c1 = c[1];
  __goblint_check(c1 == 1); // UNKNOWN
  if (c1 == 1)
    __goblint_check(1); // reachable

  return 0;
}
