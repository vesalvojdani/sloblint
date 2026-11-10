#include <goblint.h>

void f(int depth, int *outer) {
  int x; // one variable for the x of every activation
  if (depth == 0) {
    f(1, &x);
    return;
  }
  int *p = outer; // the caller's x
  int *q = &x;    // this activation's x
  if (p != q)
    __goblint_check(1); // reachable
}

int main(void) {
  f(0, 0);
  return 0;
}
