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

void *t1(void *arg) {
  pthread_mutex_lock(&rec); // DEADLOCK
  if (pthread_mutex_trylock(&rec) == 0) { // DEADLOCK
    pthread_mutex_unlock(&rec); // rec is still held once
    pthread_mutex_lock(&mutex1); // DEADLOCK
    g1 = g2 + 1;
    pthread_mutex_unlock(&mutex1);
  }
  pthread_mutex_unlock(&rec);
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t1, NULL);

  pthread_mutex_lock(&mutex1); // DEADLOCK
  pthread_mutex_lock(&rec); // DEADLOCK
  g2 = g1 + 1;
  pthread_mutex_unlock(&rec);
  pthread_mutex_unlock(&mutex1);

  pthread_join(id, NULL);
  printf("g1 = %d, g2 = %d.\n", g1, g2);
  return 0;
}
