//PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>
#include <setjmp.h>

jmp_buf env;

// The second call allocates, frees and jumps back to main, which then uses
// the block freed after the first call.
int *mk(int jump) {
  int *p = malloc(sizeof(int));
  if (jump) {
    free(p);
    longjmp(env, 1);
  }
  return p;
}

int main(void) {
  int *q = mk(0);
  free(q);
  if (!setjmp(env)) {
    mk(1);
  } else {
    *q = 1; //WARN
  }
  return 0;
}
