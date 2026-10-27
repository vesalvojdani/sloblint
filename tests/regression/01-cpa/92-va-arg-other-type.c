// PARAM: --enable ana.float.interval
// va_arg at a type of the same kind as the argument but another size, and an argument whose value is a thread ID.
#include <goblint.h>
#include <pthread.h>
#include <stdarg.h>
#include <stddef.h>

long as_long(int n, ...) {
  va_list ap;
  va_start(ap, n);
  long l = va_arg(ap, long);
  va_end(ap);
  return l;
}

long double as_long_double(int n, ...) {
  va_list ap;
  va_start(ap, n);
  long double d = va_arg(ap, long double);
  va_end(ap);
  return d;
}

unsigned long second(int n, ...) {
  va_list ap;
  va_start(ap, n);
  unsigned long a = va_arg(ap, unsigned long);
  unsigned long b = va_arg(ap, unsigned long);
  va_end(ap);
  return b;
}

void *t(void *arg) {
  return NULL;
}

int main(void) {
  long l = as_long(0, -1);
  __goblint_check(l == -1); // UNKNOWN!
  long double d = as_long_double(0, 1.5);
  __goblint_check(d == 1.5L); // UNKNOWN!
  pthread_t id;
  pthread_create(&id, NULL, t, NULL);
  unsigned long b = second(2, 5UL, id);
  __goblint_check(b == 5); // UNKNOWN!
  pthread_join(id, NULL);
  return 0;
}
