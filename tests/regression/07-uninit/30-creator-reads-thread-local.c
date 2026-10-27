// PARAM: --set ana.activated[+] uninit
// The creating thread reads a local of the thread it created.
// Its reads of its own local after initializing it are not reported, although that local escaped uninitialized.
#include <pthread.h>

int *gp;
int done;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void *publish(void *arg) {
  int z;
  pthread_mutex_lock(&m);
  gp = &z;
  pthread_mutex_unlock(&m);
  int d = 0;
  while (!d) {
    pthread_mutex_lock(&m);
    d = done;
    pthread_mutex_unlock(&m);
  }
  return NULL;
}

int main(void) {
  int x;
  pthread_t id;
  int *p = NULL;
  pthread_create(&id, NULL, publish, &x);
  while (p == NULL) {
    pthread_mutex_lock(&m);
    p = gp;
    pthread_mutex_unlock(&m);
  }
  int r = *p; // WARN
  pthread_mutex_lock(&m);
  done = 1;
  pthread_mutex_unlock(&m);
  pthread_join(id, NULL);
  x = 1;
  int s = x; // NOWARN
  int *q = &x;
  int t = *q; // NOWARN
  return 0;
}
