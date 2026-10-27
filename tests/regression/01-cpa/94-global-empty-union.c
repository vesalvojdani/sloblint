// Globals whose types contain a union without members (a GNU extension), without initializers.
#include <goblint.h>
#include <stdarg.h>
#include <string.h>

union E {};
union E e;
union E es[3];
struct T { int a; union E e; int b; } t;
struct S { va_list ap; union E e; int k; } s;

int main(void) {
  __goblint_check(t.a == 0);
  __goblint_check(t.b == 0);
  __goblint_check(s.k == 0);

  union E v = e;
  struct T t2 = t;
  __goblint_check(t2.b == 0);
  memcpy(&v, &es[1], sizeof v);
  t.e = v;
  __goblint_check(t.a == 0);
  __goblint_check(t.b == 0);
  __goblint_check(sizeof(union E) == 0);
  return 0;
}
