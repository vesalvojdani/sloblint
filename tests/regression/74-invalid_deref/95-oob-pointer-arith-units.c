// PARAM: --set ana.activated[+] memOutOfBounds --enable ana.int.interval
// Pointer arithmetic counts objects of the pointer's target type, and memOutOfBounds converts the resulting offset to bytes with the types of the object pointed into.
#include <stdlib.h>
#include <string.h>

int main(void) {
  int *ib = malloc(3 * sizeof(int)); // 12 bytes
  if (ib == NULL) return 1;
  char *c = (char *)(ib + 2); // byte 8
  c[5] = 1; // WARN
  char *d = (char *)(ib + 3); // one past the end
  *d = 1; // WARN
  memset(ib + 2, 0, 8); // WARN
  memset(ib + 2, 0, 4); // NOWARN

  // The same through a void * variable.
  void *v = ib + 2;
  char *cv = v;
  cv[5] = 1; // WARN
  memset(v, 0, 8); // WARN

  int a[3];
  char *e = (char *)(a + 2);
  e[5] = 1; // WARN

  // An int pointer into a char array advances by four bytes.
  char buf[12];
  int *ip = (int *)(buf + 4);
  ip[1] = 1; // NOWARN
  ip[2] = 1; // WARN

  free(ib);
  return 0;
}
