// PARAM: --enable ana.float.interval
// va_arg at a type of the same kind as the argument but another size, an argument whose value is a thread ID,
// and the representation of a va_list read and written through another pointer type.
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

unsigned read_repr(int n, ...) {
  va_list ap;
  va_start(ap, n);
  void *vp = (void *)ap;
  unsigned u = *(unsigned *)vp;
  va_end(ap);
  return u;
}

int write_repr(int n, ...) {
  va_list ap;
  va_start(ap, n);
  void *vp = (void *)ap;
  *(unsigned *)vp = 48;
  int i = va_arg(ap, int);
  va_end(ap);
  return i;
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
  unsigned u = read_repr(1, 5);
  __goblint_check(u == 5); // UNKNOWN!
  int i = write_repr(1, 5);
  __goblint_check(i == 5); // UNKNOWN!
  return 0;
}
