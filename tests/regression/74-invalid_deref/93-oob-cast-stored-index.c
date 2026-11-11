// PARAM: --set ana.activated[+] memOutOfBounds --enable ana.int.interval
// Pointer arithmetic on an int pointer, then a cast to a char or void pointer: the stored index counts ints, not bytes.
#include <stdlib.h>
#include <string.h>

int main(void) {
  int *ib = malloc(3 * sizeof(int)); // 12 bytes
  if (ib == NULL) return 1;
  char *c = (char *)(ib + 2); // byte 8
  c[3] = 1; // NOWARN
  c[5] = 1; // WARN
  char *d = (char *)(ib + 3); // one past the end
  *d = 1; // WARN
  memset(ib + 2, 0, 8); // WARN
  int a[3];
  char *e = (char *)(a + 2);
  e[5] = 1; // WARN
  free(ib);
  return 0;
}
