// A va_list whose address is stored in a global while another thread runs: va_arg in the variadic function still reads the arguments.
#include <goblint.h>
#include <pthread.h>
#include <stdarg.h>
#include <stddef.h>

va_list *gap;

void *u(void *arg) {
  return NULL;
}

void set(int n, ...) {
  va_list ap;
  va_start(ap, n);
  gap = &ap;
  int *p = va_arg(ap, int *);
  *p = n;
  va_end(ap);
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, u, NULL);
  int a = 0;
  set(1, &a);
  __goblint_check(a == 1); // UNKNOWN (a is reachable from gap, so it has escaped)
  return 0;
}
