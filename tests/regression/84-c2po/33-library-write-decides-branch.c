// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts
// memset may overwrite x->next, so the branch on x->next == a must not be
// decided by the equality established before the call.
#include <stdlib.h>
#include <string.h>
#include <goblint.h>

typedef struct list { long head; struct list *next; } list_t;

int main(int argc, char **argv) {
  list_t *x = malloc(sizeof(list_t));
  list_t *a = malloc(sizeof(list_t));
  x->next = a;
  if (argc > 1)
    memset(&x->next, 0, sizeof(list_t *));
  int r;
  if (x->next == a)
    r = 1;
  else
    r = 2;
  __goblint_check(r == 2); // UNKNOWN!
  return 0;
}
