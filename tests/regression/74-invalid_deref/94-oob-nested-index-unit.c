// PARAM: --set ana.activated[+] memOutOfBounds --enable ana.int.interval
// A pointer to a field of the second struct of a block: the stored index counts structs, not ints.
#include <stdlib.h>
#include <string.h>

struct s {
  int a;
  int b;
};

struct t3 {
  int x, y, z;
};

int main(void) {
  struct s *q = malloc(12);
  if (q == NULL) return 1;
  int *p = &q[1].b; // byte 12, one past the end
  *p = 2; // WARN
  int *r = &q[0].b; // byte 4
  *r = 1; // NOWARN
  struct s *t = malloc(10);
  if (t == NULL) return 1;
  memset(&t[1].a, 0, 4); // WARN
  struct s arr[1];
  int *u = &arr[1].a; // byte 8, one past the end
  *u = 3; // WARN
  struct t3 big[1];
  struct t3 *v = (struct t3 *)&((struct s *)&big[1])->a; // byte 12, one past the end
  v->x = 4; // WARN
  free(q);
  free(t);
  return 0;
}
