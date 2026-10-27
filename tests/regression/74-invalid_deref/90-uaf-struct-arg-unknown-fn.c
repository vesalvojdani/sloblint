//PARAM: --set ana.activated[+] useAfterFree --disable warn.imprecise --disable warn.unsound
// A function without a definition may dereference the pointer in a struct passed by value.
#include <stdlib.h>

struct s { int *p; };
void ext(struct s a);
void ext_ptr(int *p);

int main() {
  int *p = malloc(sizeof(int));
  int *q = malloc(sizeof(int));
  int *r = malloc(sizeof(int));
  free(p);
  free(q);

  struct s v;
  v.p = p;
  ext(v); //WARN

  ext_ptr(q); //WARN

  struct s w;
  w.p = r;
  ext(w); //NOWARN
  free(r);
  return 0;
}
