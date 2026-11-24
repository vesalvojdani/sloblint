// SKIP PARAM: --set ana.activated[+] affeq --set sem.int.signed_overflow assume_none
// As 32-widen-different-env.c, without the thread F, so that main
// publishes its initial values at the creation of U. Main's node is then
// re-evaluated, and widening that drops the other contribution made the two
// contributions replace each other without end.
#include <pthread.h>
#include <goblint.h>
int g, h, k, l;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
void *T(void *arg) {
  g = 1;
  pthread_mutex_lock(&m);
  h = 0; k = 0; l = 1;
  for (int i = 0; i < 3; i++) { int t = h; h = k + 1; k = t; }
  pthread_mutex_unlock(&m);
  return 0;
}
void *U(void *arg) {
  pthread_mutex_lock(&m);
  __goblint_check(l == 1); // UNKNOWN!
  pthread_mutex_unlock(&m);
  return 0;
}
int main() {
  pthread_t a, b;
  h = 0; k = 0; l = 0;
  pthread_create(&b, 0, U, 0);
  pthread_create(&a, 0, T, 0);
  return 0;
}
