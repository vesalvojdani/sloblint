// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 4
// A library function given a pointer to an array element may write every element of the array.
#include <unistd.h>
#include <goblint.h>

struct s {
  int before;
  char buf[4];
  int after;
};

int main(void) {
  char a[4] = {1, 2, 3, 4};
  read(0, a, 4);
  __goblint_check(a[0] == 1); // UNKNOWN!
  __goblint_check(a[3] == 4); // UNKNOWN!

  char c[4] = {1, 2, 3, 4};
  read(0, &c[1], 3);
  __goblint_check(c[3] == 4); // UNKNOWN!
  __goblint_check(c[0] == 1); // UNKNOWN (read does not write c[0], but c is invalidated as a whole)

  char *p = c + 2;
  c[3] = 4;
  read(0, p, 2);
  __goblint_check(c[3] == 4); // UNKNOWN!

  struct s s = {.before = 9, .buf = {1, 2, 3, 4}, .after = 11};
  read(0, s.buf, 4);
  __goblint_check(s.buf[2] == 3); // UNKNOWN!
  __goblint_check(s.before == 9);
  __goblint_check(s.after == 11);

  // A pointer to the first element of a nested array may access all of the outer array.
  char m[2][2] = {{1, 2}, {3, 4}};
  read(0, &m[0][0], sizeof m);
  __goblint_check(m[1][1] == 4); // UNKNOWN!

  char j[2][2] = {{1, 2}, {3, 4}};
  read(0, (char *)&j, sizeof j);
  __goblint_check(j[1][1] == 4); // UNKNOWN!
  return 0;
}
