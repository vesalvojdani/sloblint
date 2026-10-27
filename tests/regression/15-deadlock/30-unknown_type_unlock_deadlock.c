// PARAM: --set ana.activated[+] deadlock
#include <pthread.h>
#include <stdio.h>

int g1, g2;
pthread_mutex_t m; // recursive or not, depending on argc
pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;

void *t1(void *arg) {
  pthread_mutex_lock(&m); // DEADLOCK
  pthread_mutex_lock(&m); // DEADLOCK
  pthread_mutex_unlock(&m); // m is still held once if it is recursive
  pthread_mutex_lock(&mutex1); // DEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&mutex1);
  pthread_mutex_unlock(&m);
  return NULL;
}

int main(int argc, char *argv[]) {
  pthread_mutexattr_t attr;
  pthread_mutexattr_init(&attr);
  pthread_mutexattr_settype(&attr, argc > 1 ? PTHREAD_MUTEX_NORMAL : PTHREAD_MUTEX_RECURSIVE);
  pthread_mutex_init(&m, &attr);

  pthread_t id;
  pthread_create(&id, NULL, t1, NULL);

  pthread_mutex_lock(&mutex1); // DEADLOCK
  pthread_mutex_lock(&m); // DEADLOCK
  g2 = g1 + 1;
  pthread_mutex_unlock(&m);
  pthread_mutex_unlock(&mutex1);

  pthread_join(id, NULL);
  printf("g1 = %d, g2 = %d.\n", g1, g2);
  return 0;
}
