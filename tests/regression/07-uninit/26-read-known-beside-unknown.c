// PARAM: --set ana.activated[+] uninit --disable warn.unsound --disable warn.unknown
#include <stdlib.h>

int main() {
  int x;
  int y[2] = {0, 0};
  int *p = rand() ? y : NULL;
  int *q = p + 1; // &y[1], or NULL + 1, which is the unknown pointer
  int r = *q; // NOWARN
  if (rand())
    q = &x;
  r = *q; // WARN
  if (*q) // WARN
    r = 1;
  *q = 1; // init_lval initializes only when q has a single target
  int s = *q; // TODO NOWARN
  return r + s;
}
