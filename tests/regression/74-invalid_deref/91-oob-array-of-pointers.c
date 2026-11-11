// PARAM: --set ana.activated[+] memOutOfBounds --enable ana.int.interval
// Dereferences of pointers that are elements of arrays: the arrays themselves are not pointers.
#include <stdlib.h>
#include <string.h>
#include <alloca.h>

struct s {
  char *arr[2];
};

int main() {
  char *b[2];
  b[0] = malloc(4);
  b[1] = malloc(4);
  b[1][3] = 1; // NOWARN
  b[1][5] = 1; // WARN
  char c = b[1][5]; // WARN
  b[0][3] = b[1][3]; // NOWARN

  int i = rand() % 2;
  b[i][3] = 1; // NOWARN
  b[i][5] = 1; // WARN

  char *a[2];
  for (int j = 0; j < 2; j++)
    a[j] = alloca(4);
  a[1][3] = 1; // NOWARN
  a[1][5] = 1; // WARN

  struct s s;
  s.arr[0] = malloc(4);
  s.arr[1] = malloc(4);
  s.arr[1][3] = 1; // NOWARN
  s.arr[1][5] = 1; // WARN

  char **pp[2];
  pp[0] = b;
  pp[1] = b;
  pp[1][1][3] = 1; // NOWARN
  pp[1][1][5] = 1; // WARN

  b[0][1] = 'a';
  b[0][2] = 0;
  char *q[1];
  q[0] = b[0] + 1;
  size_t n = strlen(q[0]); // NOWARN
  char *r[1];
  r[0] = b[0] + 10;
  n = strlen(r[0]); // WARN

  return 0;
}
