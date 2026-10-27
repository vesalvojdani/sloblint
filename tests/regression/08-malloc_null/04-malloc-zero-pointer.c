// PARAM: --set ana.activated[+] malloc_null --set sem.malloc.zero pointer
#include <stdlib.h>
#include <goblint.h>

int main(void) {
  int *p = malloc(0); // under sem.malloc.zero pointer, the result is not the null pointer
  int x = 5;
  __goblint_check(x == 5);
  free(p);

  int *q = malloc(sizeof(int)); // malloc_null enables sem.malloc.fail: the result may be the null pointer
  if (q == NULL) {
    __goblint_check(1); // reachable
    return 1;
  }
  __goblint_check(1); // reachable
  free(q);
  return 0;
}
