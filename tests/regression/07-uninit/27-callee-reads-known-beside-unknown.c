// PARAM: --set ana.activated[+] uninit --disable warn.unsound --disable warn.unknown
#include <stdlib.h>

struct pair {
  int *known;
  int *other;
};

int read_arg(int *q) {
  return *q; // WARN
}

int read_known(struct pair *s) {
  return *s->known; // WARN
}

void write_known(struct pair *s) {
  *s->known = 1;
}

int main() {
  int x;
  int y[2] = {0, 0};
  int *p = rand() ? y : NULL;
  int *q = p + 1; // &y[1], or NULL + 1, which is the unknown pointer
  if (rand())
    q = &x;
  read_arg(q);

  struct pair s = {&x, p + 1};
  read_known(&s);
  write_known(&s);
  int r = x; // NOWARN
  return r;
}
