// SKIP PARAM: --set ana.activated[+] apron --set ana.relation.privatization top
// The callee writes a local of the caller through a pointer in a struct passed by value.
#include <goblint.h>

extern int __VERIFIER_nondet_int();

struct s { int *p; };

void inc(struct s a) {
  if (__VERIFIER_nondet_int())
    (*a.p)++;
}

int main() {
  int x = __VERIFIER_nondet_int();
  if (x > 1000)
    return 0;
  int y = x;
  struct s v;
  v.p = &x;
  inc(v);
  __goblint_check(x == y); // UNKNOWN!
  __goblint_check(x >= y);
  return 0;
}
