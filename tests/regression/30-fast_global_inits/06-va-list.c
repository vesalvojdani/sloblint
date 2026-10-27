// PARAM: --disable exp.fast_global_inits
// Arrays of structs containing a va_list, without initializers.
#include <goblint.h>
#include <stdarg.h>

struct A { int n; va_list ap; int m; } as[3];
va_list aps[2];

int first(int n, ...) {
  va_start(aps[1], n);
  va_copy(as[2].ap, aps[1]);
  int r = va_arg(as[2].ap, int);
  va_end(as[2].ap);
  va_end(aps[1]);
  return r;
}

int main(void) {
  __goblint_check(as[0].n == 0);
  __goblint_check(as[2].m == 0);
  int r = first(1, 4);
  __goblint_check(r == 4); // TODO
  __goblint_check(as[2].m == 0);
  return 0;
}
