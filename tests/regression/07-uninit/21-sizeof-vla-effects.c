// PARAM: --set ana.activated[+] uninit
#include <stdlib.h>

// sizeof evaluates a variable-length operand, so the temporaries holding its calls and increments are assigned before they are read.
int f(void) { return 0; }
int buf[4];
int *q(void) { return buf; }

int main(void) {
  int n = rand() % 3 + 1;
  int vla[n][n];
  int i = 0;
  size_t a = sizeof(vla[f()]); // NOWARN
  size_t b = sizeof(vla[i++]); // NOWARN
  size_t c = sizeof(*(int (*)[n])q()); // NOWARN
  return 0;
}
