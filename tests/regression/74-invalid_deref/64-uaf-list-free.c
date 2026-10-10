//PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>

typedef struct list { int head; struct list *next; } list_t;

int main(void) {
  list_t *top = malloc(sizeof(list_t));
  list_t *cur = top;
  for (int i = 0; i < 10; i++) {
    if (i == 9)
      cur->next = NULL;
    else
      cur->next = malloc(sizeof(list_t));
    cur = cur->next;
  }
  // Every node is freed once. The nodes from the second allocation site are
  // one abstract block, so freeing one of them marks all of them as freed.
  list_t *xs = top;
  while (xs != NULL) {
    list_t *next = xs->next; // TODO NOWARN (one abstract block per allocation site)
    free(xs); // TODO NOWARN (one abstract block per allocation site)
    xs = next;
  }
  return 0;
}
