// PARAM: --set ana.activated[+] uninit
// A thread reads locals that escape only after it was created:
// x of its creator, and y of a function its creator calls after creating it.
#include <pthread.h>

int *gx;
int *gy;
pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;

void put(int **g, int *p) {
  pthread_mutex_lock(&m);
  *g = p;
  pthread_mutex_unlock(&m);
}

int *wait_for(int **g) {
  int *p = NULL;
  while (p == NULL) {
    pthread_mutex_lock(&m);
    p = *g;
    pthread_mutex_unlock(&m);
  }
  return p;
}

void *reader(void *arg) {
  int *px = wait_for(&gx);
  int rx = *px; // WARN
  int *py = wait_for(&gy);
  int ry = *py; // WARN
  return NULL;
}

void publish_local(pthread_t id) {
  int y;
  put(&gy, &y);
  pthread_join(id, NULL);
}

int main(void) {
  int x;
  pthread_t id;
  pthread_create(&id, NULL, reader, NULL);
  put(&gx, &x);
  publish_local(id);
  return 0;
}
