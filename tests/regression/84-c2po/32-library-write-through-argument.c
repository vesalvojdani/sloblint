// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts
// memcpy overwrites x->next, so the equality x->next == a established before
// the call does not hold afterwards.
#include <stdlib.h>
#include <string.h>
#include <goblint.h>

typedef struct list { long head; struct list *next; } list_t;

int main(int argc, char **argv) {
  list_t *x = malloc(sizeof(list_t));
  list_t *a = malloc(sizeof(list_t));
  list_t *src = argc > 1 ? a : NULL;
  x->next = a;
  memcpy(&x->next, &src, sizeof src);
  __goblint_check(x->next == a); // UNKNOWN!
  return 0;
}
