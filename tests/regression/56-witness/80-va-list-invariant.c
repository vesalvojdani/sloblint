// CRAM
#include <stdarg.h>

struct s { int a; };

int sum(int n, ...) {
  va_list ap;
  va_start(ap, n);
  struct s x = va_arg(ap, struct s);
  struct s y = va_arg(ap, struct s);
  va_end(ap);
  return x.a + y.a;
}

int main(void) {
  struct s x = {3}, y = {4};
  int r = sum(2, x, y);
  return 0;
}
