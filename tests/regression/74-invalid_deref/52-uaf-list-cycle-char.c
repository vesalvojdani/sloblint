// PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>

// A ten-element list whose last node is linked back to the head byte by byte.
// The loop freeing the list reads the freed head's next and frees the head a
// second time.
typedef struct list { int head; struct list *next; } list_t;

int main(void) {
  list_t *top = malloc(sizeof(list_t));
  list_t *cur = top;
  for (int i = 0; i < 10; i++) {
    if (i == 9) {
      char *dst = (char *)&cur->next, *src = (char *)&top;
      for (unsigned k = 0; k < sizeof top; k++)
        dst[k] = src[k];
    } else
      cur->next = malloc(sizeof(list_t));
    cur = cur->next;
  }
  list_t *xs = top;
  while (xs != 0) {
    list_t *next = xs->next; // WARN
    free(xs); // WARN
    xs = next;
  }
  return 0;
}
