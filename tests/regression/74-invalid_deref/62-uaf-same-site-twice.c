//PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>

// Each call allocates, writes and frees a new block. The block from the
// first call is unreachable when the second call allocates, so the second
// call's accesses are to the new block.
void f(void) {
  int *p = malloc(sizeof(int));
  *p = 1; //NOWARN
  free(p); //NOWARN
}

// The same within one function. When the next block is allocated, p still
// holds the address of the previous one, so that block counts as reachable.
void loop(void) {
  for (int i = 0; i < 3; i++) {
    int *p = malloc(sizeof(int));
    *p = i; // TODO NOWARN (p still points to the previous block)
    free(p); // TODO NOWARN (p still points to the previous block)
  }
}

int main(void) {
  f();
  f();
  loop();
  return 0;
}
