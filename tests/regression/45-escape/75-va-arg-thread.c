// A pointer that a variadic function reads with va_arg reaches a thread.
#include <goblint.h>
#include <pthread.h>
#include <stdarg.h>
#include <stddef.h>

int *g;

void *t(void *arg) {
  int *p = arg;
  *p = 1; // RACE!
  return NULL;
}

void spawn(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int *p = va_arg(ap, int *);
  pthread_t id;
  pthread_create(&id, NULL, t, p);
  va_end(ap);
}

void stash(int n, ...) {
  va_list ap;
  va_start(ap, n);
  g = va_arg(ap, int *);
  va_end(ap);
}

void *u(void *arg) {
  *g = 2; // RACE!
  return NULL;
}

int main(void) {
  int x = 0;
  spawn(1, &x);
  int vx = x; // RACE!
  __goblint_check(vx == 0); // UNKNOWN!

  int y = 0;
  stash(1, &y);
  pthread_t id;
  pthread_create(&id, NULL, u, NULL);
  int vy = y; // RACE!
  __goblint_check(vy == 0); // UNKNOWN!
  return 0;
}
