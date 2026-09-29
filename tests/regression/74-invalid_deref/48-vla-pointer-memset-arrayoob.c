// PARAM: --set ana.activated[+] memOutOfBounds --enable ana.int.interval --enable ana.arrayoob
// As 47-vla-pointer-memset, with ana.arrayoob: computing the size of a variable-length array does not check array bounds.
#include <string.h>

int main(void) {
  int n = 2;

  // The size of a variable-length array is computed from its length at the declaration.
  int a[n];
  int (*pa)[n];
  pa = &a;
  memset(pa, 0, 3 * sizeof(int)); // WARN

  int b[n];
  int (*pb)[n];
  pb = &b;
  memset(pb, 0, 2 * sizeof(int)); // NOWARN

  int c[n][n];
  int (*pc)[n];
  pc = &c[0];
  memset(pc, 0, 5 * sizeof(int)); // WARN

  int d[n][n];
  int (*pd)[n];
  pd = &d[0];
  memset(pd, 0, 4 * sizeof(int)); // NOWARN

  // The length is the value of n at the declaration, not at the access.
  int e[n][n];
  int (*pe)[n];
  pe = &e[0];
  n = 10;
  memset(pe, 0, 5 * sizeof(int)); // WARN
  return 0;
}
