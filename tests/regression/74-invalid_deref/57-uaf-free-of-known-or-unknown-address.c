// PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>

// publish and lookup have no definition: publish may keep h's address, and
// lookup may return it. p points to h's object or to the address lookup
// returns, so the free may free h's object.
extern void publish(int *p);
extern int *lookup(void);
extern int choose(void);

int main(void) {
  int *h = malloc(sizeof(int));
  publish(h);
  int *p = h;
  if (choose())
    p = lookup();
  *h = 1; // NOWARN
  free(p);
  *h = 2; // WARN
  return 0;
}
