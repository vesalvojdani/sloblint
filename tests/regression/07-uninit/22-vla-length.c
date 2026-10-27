// PARAM: --set ana.activated[+] uninit
#include <stddef.h>

int main() {
  int n = 2;
  int k;
  int j;
  int i;

  // sizeof of a variable-length array type evaluates its lengths (C11 6.5.3.4p2)
  size_t s1 = sizeof(int[k]); // WARN
  size_t s2 = sizeof(int[n][j]); // WARN
  size_t s3 = sizeof(int[n][2]); // NOWARN

  // a declaration evaluates the lengths of its variable-length array declarators, also under a pointer and in a return type, but not in parameters (C11 6.8p3, 6.7.6.2p5)
  int a[n][i]; // WARN
  int b[n]; // NOWARN
  int w;
  int (*p)[w]; // WARN
  int (*q)[n]; // NOWARN
  int v;
  int (*(*f)(void))[v]; // WARN
  int (*(*g)(int x[k]))[n]; // NOWARN

  return 0;
}
