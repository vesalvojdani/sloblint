// PARAM: --set ana.activated[+] deadlock
#define _GNU_SOURCE
#include <pthread.h>
#include <stdio.h>

int g1, g2;
#ifdef __APPLE__
pthread_mutex_t rec = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;
#else
pthread_mutex_t rec = PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP;
#endif
pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex2 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex3 = PTHREAD_MUTEX_INITIALIZER;

void *t1(void *arg) {
  pthread_mutex_lock(&rec); // DEADLOCK
  pthread_mutex_lock(&rec); // DEADLOCK
  pthread_mutex_unlock(&rec); // rec is still held once
  pthread_mutex_lock(&mutex1); // DEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&mutex1);
  pthread_mutex_unlock(&rec);

  pthread_mutex_lock(&mutex2); // NODEADLOCK
  pthread_mutex_unlock(&mutex2); // mutex2 is not recursive, so it is no longer held
  pthread_mutex_lock(&mutex3); // NODEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&mutex3);
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t1, NULL);

  pthread_mutex_lock(&mutex3); // NODEADLOCK
  pthread_mutex_lock(&mutex2); // NODEADLOCK
  g2 = g1 + 1;
  pthread_mutex_unlock(&mutex2);
  pthread_mutex_unlock(&mutex3);

  pthread_mutex_lock(&mutex1); // DEADLOCK
  pthread_mutex_lock(&rec); // DEADLOCK
  g2 = g1 + 1;
  pthread_mutex_unlock(&rec);
  pthread_mutex_unlock(&mutex1);

  pthread_join(id, NULL);
  printf("g1 = %d, g2 = %d.\n", g1, g2);
  return 0;
}
