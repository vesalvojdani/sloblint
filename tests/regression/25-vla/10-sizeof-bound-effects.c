#include <goblint.h>
#include <stddef.h>

// An array length containing the sizeof of a variable-length array is not an integer constant expression (C11 6.7.6.2p4),
// so an array with such a length is a variable-length array and sizeof evaluates it (C11 6.5.3.4p2).
int g;
int f(void) { g++; return 0; }

int main(int argc, char **argv) {
  int n = argc + 1;
  int vla[n][n];
  int c[2][sizeof vla];

  size_t s1 = sizeof(c[f()]);
  __goblint_check(g == 1);

  size_t s2 = sizeof(int[sizeof(vla[f()])]);
  __goblint_check(g == 2);

  // An array length containing the sizeof of a fixed-size array is constant.
  int d[2][sizeof(int[4])];
  size_t s3 = sizeof(d[f()]);
  __goblint_check(g == 2);
  return 0;
}
