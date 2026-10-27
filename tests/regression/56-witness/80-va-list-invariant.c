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

int first(int n, ...) {
  va_list ap;
  va_start(ap, n);
  void *vp = (void *)ap;
  int i = va_arg(ap, int);
  va_end(ap);
  return i + (vp != 0);
}

int main(void) {
  struct s x = {3}, y = {4};
  int r = sum(2, x, y);
  int f = first(2, 5, 6);
  return 0;
}
