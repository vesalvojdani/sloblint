// SKIP PARAM: --set ana.activated[+] affeq --set sem.int.signed_overflow assume_none
// Main publishes h = k = l = 0 to the mutex-meet initial values when it
// creates F. T's loop head in the critical section publishes there as well,
// with environment {h,k,l}, since g is unprotected. Its values grow, so the
// initial values become a widening point. Widening with different
// environments must not drop main's contribution, which is not sent again.
// U, joined before T is created, reads l == 0.
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
void *F(void *arg) { return 0; }
int main() {
  pthread_t a, b, c;
  h = 0; k = 0; l = 0;
  pthread_create(&c, 0, F, 0);
  pthread_create(&b, 0, U, 0);
  pthread_join(b, 0);
  pthread_create(&a, 0, T, 0);
  pthread_join(a, 0);
  pthread_join(c, 0);
  return 0;
}
