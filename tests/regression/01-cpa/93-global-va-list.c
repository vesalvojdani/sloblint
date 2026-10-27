// Globals whose types contain a va_list, without initializers.
#include <goblint.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stddef.h>

struct H { va_list ap; int k; } h;
va_list g, g2;
union U { va_list ap; long l; } u;
struct Big { long a, b, c; int *p; };
union W { va_list ap; struct Big s; } w;
struct A { int n; va_list a[2]; int m; } as[3];

int sum(int n, ...) {
  static va_list s;
  static int calls;
  calls++;
  va_start(g, n);
  va_copy(g2, g);
  va_copy(h.ap, g);
  va_copy(s, g);
  int r = 0;
  for (int i = 0; i < n; i++)
    r += va_arg(g, int);
  int a = va_arg(g2, int);
  int b = va_arg(h.ap, int);
  int c = va_arg(s, int);
  __goblint_check(a == b); // TODO
  __goblint_check(a == c); // TODO
  va_end(s);
  va_end(h.ap);
  va_end(g2);
  va_end(g);
  return r;
}

// Reads the global va_list that its caller started.
int next(void) {
  return va_arg(g, int);
}

int first(int n, ...) {
  va_start(g, n);
  int r = next();
  va_end(g);
  return r;
}

int main(void) {
  __goblint_check(h.k == 0);
  __goblint_check(as[1].n == 0);
  __goblint_check(as[2].m == 0);
  __goblint_check(u.l == 0); // UNKNOWN
  __goblint_check(w.s.a == 0);
  __goblint_check(w.s.p == NULL);

  int r = sum(2, 3, 4);
  __goblint_check(r == 7); // TODO
  r = sum(1, 5);
  __goblint_check(r == 5); // TODO
  __goblint_check(h.k == 0);

  int x = rand() % 2;
  r = sum(1, x);
  __goblint_check(r == 0); // UNKNOWN!
  r = first(1, x);
  __goblint_check(r == 0); // UNKNOWN!
  r = first(1, 6);
  __goblint_check(r == 6); // TODO
  return 0;
}
