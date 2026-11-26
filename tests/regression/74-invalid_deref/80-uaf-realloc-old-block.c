//PARAM: --set ana.activated[+] useAfterFree
// realloc frees its old block if it moves the block.
#include <stdlib.h>

void use() {
  char *p = malloc(4);
  char *q = realloc(p, 100000);
  q[0] = 'x'; // NOWARN
  p[0] = 'x'; // WARN
  free(q); // NOWARN
}

void free_old() {
  char *p = malloc(4);
  char *q = realloc(p, 100000);
  free(p); // WARN
}

int main() {
  use();
  free_old();
  return 0;
}
