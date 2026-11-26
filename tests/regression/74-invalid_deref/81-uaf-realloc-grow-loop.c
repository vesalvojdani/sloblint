//PARAM: --set ana.activated[+] useAfterFree
// A buffer grown by realloc in a loop. The block that realloc returns in one
// iteration is the old block of the next, and the analysis has one heap
// variable for all blocks that the realloc call returns, so it reports the
// buffer in the loop as freed.
#include <stdlib.h>

int main() {
  char *p = malloc(4);
  for (int i = 0; i < 10; i++) {
    p = realloc(p, 8 * (i + 1)); // NOWARN TODO
    p[0] = 'x'; // NOWARN TODO
  }
  free(p); // NOWARN TODO
  return 0;
}
