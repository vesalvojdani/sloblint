#include <goblint.h>

int main(void) {
  int n = 2;
  int a[n][n];
  int (*p)[n];
  int (*q)[n];
  p = &a[1];
  q = &a[0];
  // Comparing the addresses computes byte offsets with the element type int[n], which has no compile-time size.
  __goblint_check(p != q); // TODO
  __goblint_check(p == &a[1]); // TODO
  return 0;
}
