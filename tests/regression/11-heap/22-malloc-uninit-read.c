// Base holds no value for memory returned by malloc until the program writes it.
// A read that joins this missing value with a value read through another pointer,
// or that dereferences it, relies on the memory being written before it is read,
// and declares this assumption.
#include <stdlib.h>

typedef struct { int *p; int x; } task_t;
int g;

int main(void) {
  task_t *a = malloc(sizeof(task_t));
  a->p = &g;
  a->x = 0;
  task_t *b = malloc(sizeof(task_t));
  b->x = 0;
  // b->p is never written.
  task_t *c = calloc(1, sizeof(task_t));

  int r;
  task_t *t = r ? a : b;
  *(t->p) = 1; // WARN (assumption: b->p is read before it is written)
  int *q = t->p; // WARN (assumption: b->p is read before it is written)

  *(b->p) = 2; // WARN (assumption: b->p is dereferenced before it is written)
  *(b->p + 1) = 5; // WARN (assumption: b->p is dereferenced before it is written)

  // Read on its own, the missing value becomes an unknown pointer, which may be NULL.
  int *s = b->p; // NOWARN
  *s = 3; // WARN (May dereference NULL pointer)

  *(a->p) = 4; // NOWARN
  int x = t->x; // NOWARN (both fields were written)
  int *z = c->p; // NOWARN (calloc initializes the memory)
  return 0;
}
