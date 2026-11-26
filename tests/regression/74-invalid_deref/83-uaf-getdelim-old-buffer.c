//PARAM: --set ana.activated[+] useAfterFree
// getdelim calls realloc on *lineptr when the line does not fit.
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

int main() {
  size_t n = 2;
  char *buf = malloc(n);
  char *old = buf;
  if (getdelim(&buf, &n, ',', stdin) < 0) return 0;
  old[0] = 'x'; // WARN
  return 0;
}
