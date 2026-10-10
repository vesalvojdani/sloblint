// PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>

// publish and lookup have no definition: publish may keep a's address, and
// lookup may return it, so the pointer analysis does not know b's target.
extern void publish(int *p);
extern int *lookup(void);

int main(void) {
  int *a = malloc(sizeof(int));
  publish(a);
  int *b = lookup();
  if (b == NULL)
    return 1;
  *b = 1; // NOWARN (nothing has been freed yet)
  free(a);
  *b = 2; // WARN (b may point to a's freed object)
  return 0;
}
