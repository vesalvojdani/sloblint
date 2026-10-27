// Writes through pointers that a variadic function reads with va_arg change the caller's variables.
#include <goblint.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdlib.h>

void set_one(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int *p = va_arg(ap, int *);
  *p = n;
  va_end(ap);
}

void vset(va_list ap) {
  int *p = va_arg(ap, int *);
  *p = 2;
}

void set_through_va_list(int n, ...) {
  va_list ap;
  va_start(ap, n);
  vset(ap);
  va_end(ap);
}

void set_through_copy(int n, ...) {
  va_list ap, aq;
  va_start(ap, n);
  va_copy(aq, ap);
  int *p = va_arg(aq, int *);
  *p = 3;
  va_end(aq);
  va_end(ap);
}

void set_maybe(int c, ...) {
  va_list ap;
  va_start(ap, c);
  int *p = va_arg(ap, int *);
  if (c)
    *p = 4;
  va_end(ap);
}

int count(const char *first, ...) {
  va_list ap;
  va_start(ap, first);
  int k = 1;
  while (va_arg(ap, const char *) != NULL)
    k++;
  va_end(ap);
  return k;
}

int first_int(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int i = va_arg(ap, int);
  va_end(ap);
  return i;
}

int main(void) {
  int a = 0, b = 0, c = 0, d = 0;
  set_one(1, &a);
  __goblint_check(a == 1);
  set_through_va_list(0, &b);
  __goblint_check(b == 2);
  set_through_copy(0, &c);
  __goblint_check(c == 3);
  set_maybe(rand(), &d);
  __goblint_check(d == 0); // UNKNOWN!
  count("a", "b", (char *)NULL);
  __goblint_check(1); // reachable: the loop in count ends at the null pointer
  int i = first_int(0, 42);
  __goblint_check(i == 42);
  return 0;
}
