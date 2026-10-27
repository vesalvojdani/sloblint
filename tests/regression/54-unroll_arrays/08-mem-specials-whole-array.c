// PARAM: --set ana.base.arrays.domain unroll --set ana.base.arrays.unrolling-factor 4
// memset, bzero, memcpy and memmove given a pointer to an array element write the bytes they are given, which may be more than the element.
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <goblint.h>

struct s {
  char before;
  char buf[4];
  char after;
};

int main(void) {
  char a[4] = {1, 2, 3, 4};
  memset(a, 0, sizeof a);
  __goblint_check(a[0] == 0);
  __goblint_check(a[3] == 0);

  char b[4] = {1, 2, 3, 4};
  bzero(b, sizeof b);
  __goblint_check(b[3] == 0);

  char src[4] = {5, 6, 7, 8};
  char c[4] = {1, 2, 3, 4};
  memcpy(c, src, sizeof c);
  __goblint_check(c[0] == 5);
  __goblint_check(c[3] == 8);

  char d[4] = {1, 2, 3, 4};
  memmove(d, src, sizeof d);
  __goblint_check(d[3] == 8);

  // an array member
  struct s s = {1, {2, 3, 4, 5}, 6};
  memset(s.buf, 0, sizeof s.buf);
  __goblint_check(s.buf[3] == 0);
  __goblint_check(s.before == 1);
  __goblint_check(s.after == 6);

  // a nested array, and one row of it
  char m[2][2] = {{1, 2}, {3, 4}};
  memset(m, 0, sizeof m);
  __goblint_check(m[1][1] == 0);
  char n[2][2] = {{1, 2}, {3, 4}};
  memset(n[1], 0, sizeof n[1]);
  __goblint_check(n[0][1] == 2);
  __goblint_check(n[1][1] == 0);

  // one element through a pointer to it
  int e[4] = {1, 2, 3, 4};
  int x = 9;
  memcpy(&e[2], &x, sizeof x);
  __goblint_check(e[2] == 9);
  __goblint_check(e[3] == 4);

  // part of an array, from its first element and from the middle
  char f[4] = {1, 2, 3, 4};
  memset(f, 0, 2);
  __goblint_check(f[1] == 0); // UNKNOWN
  __goblint_check(f[3] == 4); // UNKNOWN
  char g[4] = {1, 2, 3, 4};
  char *p = &g[1];
  memset(p, 0, 2);
  __goblint_check(g[0] == 1); // UNKNOWN
  __goblint_check(g[2] == 0); // UNKNOWN
  __goblint_check(g[3] == 4); // UNKNOWN
  char h[4] = {1, 2, 3, 4};
  memcpy(h, src, 2);
  __goblint_check(h[1] == 6); // UNKNOWN
  __goblint_check(h[3] == 4); // UNKNOWN

  // a count that is not known
  char i[4] = {1, 2, 3, 4};
  int count = rand() ? 1 : 4;
  memset(i, 0, count);
  __goblint_check(i[3] == 4); // UNKNOWN!

  // more than one destination
  char j[4] = {1, 2, 3, 4};
  char k[4] = {1, 2, 3, 4};
  char *q = rand() ? j : k;
  memset(q, 0, 4);
  __goblint_check(j[3] == 0); // UNKNOWN!

  // memccpy stops after the first zero byte of src0
  char src0[4] = {5, 0, 7, 8};
  char l[4] = {1, 2, 3, 4};
  memccpy(l, src0, 0, sizeof l);
  __goblint_check(l[3] == 4); // UNKNOWN
  return 0;
}
