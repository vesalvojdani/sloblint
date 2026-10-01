//PARAM: --set ana.activated[+] useAfterFree
#include <stdlib.h>

int *g;
struct holder { int *p; } *h;

// Stores the block in g before freeing it, so g dangles after the call.
void f(void) {
  int *p = malloc(sizeof(int));
  *p = 1; // TODO NOWARN (g may reach the block of the previous call)
  g = p;
  free(p); // TODO NOWARN (g may reach the block of the previous call)
}

// In the second call, the argument points to the freed block of the first.
int *use_arg(int *old) {
  int *p = malloc(sizeof(int));
  if (old != NULL)
    *old = 2; //WARN
  free(p); // TODO NOWARN (old may reach the block of the first call)
  return p;
}

// Allocates and frees one block, but frees it twice.
void twice(void) {
  int *p = malloc(sizeof(int));
  free(p); //NOWARN
  free(p); //WARN
}

// The dangling pointer is only reachable through another block.
void through_heap(void) {
  int *p = malloc(sizeof(int));
  *p = 3; // TODO NOWARN (h->p may reach the block of the previous call)
  h->p = p;
  free(p); // TODO NOWARN (h->p may reach the block of the previous call)
}

int main(void) {
  f();
  f();
  *g = 4; //WARN

  int *q = NULL;
  for (int i = 0; i < 2; i++) {
    int *p = malloc(sizeof(int));
    *p = i; // TODO NOWARN (q may reach the block of the previous iteration)
    if (i == 0)
      q = p;
    free(p); // TODO NOWARN (q may reach the block of the previous iteration)
  }
  *q = 5; //WARN

  int *r = malloc(sizeof(int));
  free(r);
  int *s = malloc(sizeof(int)); // a different allocation site
  *r = 6; //WARN
  free(s); //NOWARN

  use_arg(use_arg(NULL));
  twice();

  h = malloc(sizeof(struct holder));
  through_heap();
  through_heap();
  *h->p = 7; //WARN
  free(h);
  return 0;
}
