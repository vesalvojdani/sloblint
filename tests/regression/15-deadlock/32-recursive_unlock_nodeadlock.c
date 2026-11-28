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
pthread_mutex_t mutex2, mutex3; // type set by an attribute

void *t1(void *arg) {
  pthread_mutex_lock(&rec); // NODEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&rec); // rec was locked once, so it is no longer held
  pthread_mutex_lock(&mutex1); // NODEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&mutex1);

  pthread_mutex_lock(&mutex2); // NODEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&mutex2); // mutex2 was locked once, so it is no longer held
  pthread_mutex_lock(&mutex3); // NODEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&mutex3);
  return NULL;
}

int main(void) {
  pthread_mutexattr_t attr;
  pthread_mutexattr_init(&attr);
  pthread_mutex_init(&mutex2, &attr);
  pthread_mutex_init(&mutex3, &attr);

  pthread_t id;
  pthread_create(&id, NULL, t1, NULL);

  pthread_mutex_lock(&mutex1); // NODEADLOCK
  pthread_mutex_lock(&rec); // NODEADLOCK
  g2 = g1 + 1;
  pthread_mutex_unlock(&rec);
  pthread_mutex_unlock(&mutex1);

  pthread_mutex_lock(&mutex3); // NODEADLOCK
  pthread_mutex_lock(&mutex2); // NODEADLOCK
  g2 = g1 + 1;
  pthread_mutex_unlock(&mutex2);
  pthread_mutex_unlock(&mutex3);

  pthread_join(id, NULL);
  printf("g1 = %d, g2 = %d.\n", g1, g2);
  return 0;
}
