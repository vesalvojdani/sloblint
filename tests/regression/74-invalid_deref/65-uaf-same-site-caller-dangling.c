//PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>

int *keep;

// The second call allocates while main's q still points to the block freed
// in the first call. Only main can reach that block.
void f(int k) {
  int *p = malloc(sizeof(int));
  if (k == 0) {
    keep = p;
    free(p);
    return;
  }
  *p = 1; //NOWARN
  free(p); //NOWARN
}

int main(void) {
  f(0);
  int *q = keep;
  keep = NULL;
  f(1);
  *q = 2; //WARN
  return 0;
}
