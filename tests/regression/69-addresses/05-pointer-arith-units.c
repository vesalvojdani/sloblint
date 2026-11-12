// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 5
// Pointer arithmetic counts objects of the pointer's target type, whatever the type of the object pointed into.
#include <goblint.h>

struct s { int x; int y; };

int main() {
  int a[5] = {0, 1, 2, 3, 4};
  char *b = (char *)a;

  // b + sizeof(int) is &a[1], not &a[4]
  int *q = (int *)(b + sizeof(int));
  __goblint_check(*q == 1);
  *q = 10;
  __goblint_check(a[1] == 10);
  __goblint_check(a[4] == 4);

  int *r = (int *)(b + 3 * sizeof(int)) - 1;
  __goblint_check(r == a + 2);
  __goblint_check(*r == 2);

  // The difference of two pointers counts objects of their target type.
  long d = (char *)(a + 3) - b;
  __goblint_check(d == 12);
  long e = (int *)(b + 8) - a;
  __goblint_check(e == 2);

  // A pointer to the whole array advances by the size of the array.
  int (*pa)[5] = &a;
  int *end = (int *)(pa + 1);
  __goblint_check(end == a + 5);
  __goblint_check(end - a == 5);

  // Moving within a struct by its members' sizes reaches the other member.
  struct s st = {5, 6};
  int *py = &st.y;
  struct s *ps = (struct s *)(py - 1);
  __goblint_check(ps == &st);
  __goblint_check(ps->x == 5);
  char *cy = (char *)&st.x + sizeof(int);
  __goblint_check(*(int *)cy == 6);

  return 0;
}
