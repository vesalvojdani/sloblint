// PARAM: --set ana.activated[+] var_eq
// An undefined function may write through a pointer in a struct passed by value.
#include <goblint.h>

struct s { int *p; };

void ext(struct s a);

int main() {
  int x = 0;
  int y = x;
  struct s v;
  v.p = &x;
  ext(v);
  __goblint_check(x == y); // UNKNOWN!
  return 0;
}
