// memset, bzero and memcpy write the number of bytes they are given, which may be fewer or more than the destination pointer's target has.
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <goblint.h>

struct pair {
  char first;
  char second;
};

struct triple {
  char a;
  char b;
  char c;
};

struct buffer {
  char buf[4];
  int after;
};

struct ints {
  int x;
  int y;
};

int main(void) {
  struct pair p = {1, 2};
  memset(&p, 0, sizeof p);
  __goblint_check(p.second == 0);

  struct pair q = {1, 2};
  memset(&q, 0, 1);
  __goblint_check(q.first == 0); // UNKNOWN
  __goblint_check(q.second == 2); // UNKNOWN

  struct pair r = {1, 2};
  bzero(&r, 1);
  __goblint_check(r.second == 2); // UNKNOWN

  int x = 0x01010101;
  memset(&x, 0, 1);
  __goblint_check(x != 0); // UNKNOWN

  // a count that is not known
  struct pair s = {1, 2};
  int count = rand() ? 1 : 2;
  memset(&s, 0, count);
  __goblint_check(s.second == 2); // UNKNOWN!

  // memccpy stops after the first zero byte of u
  struct triple t = {1, 2, 3};
  struct triple u = {5, 0, 7};
  memccpy(&t, &u, 0, sizeof t);
  __goblint_check(t.c == 3); // UNKNOWN

  // more bytes than the first member that the pointer points to
  struct pair v = {1, 2};
  memset(&v.first, 0, sizeof v);
  __goblint_check(v.second == 0);

  struct buffer b = {{1, 2, 3, 4}, 5};
  memset(b.buf, 0, sizeof b);
  __goblint_check(b.after == 0);

  struct pair w = {1, 2};
  char *c = (char *)&w;
  memset(c, 0, sizeof w);
  __goblint_check(w.second == 0);

  // a count that is not known, from a member
  struct ints y = {1, 2};
  int count2 = rand() ? sizeof(int) : sizeof y;
  memset(&y.x, 0, count2);
  __goblint_check(y.y == 2); // UNKNOWN!

  // more bytes than the member of allocated memory that the pointer points to
  struct ints *h = malloc(sizeof *h);
  h->x = 1;
  h->y = 2;
  memset(&h->x, 0, sizeof *h);
  __goblint_check(h->y == 0); // UNKNOWN
  return 0;
}
