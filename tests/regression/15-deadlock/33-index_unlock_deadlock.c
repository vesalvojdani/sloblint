// PARAM: --set ana.activated[+] deadlock
#include <pthread.h>
#include <stdio.h>

int g1, g2;
pthread_mutex_t m[2] = {PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER};
pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;
int i, j;

void *t1(void *arg) {
  pthread_mutex_lock(&m[i]); // DEADLOCK
  pthread_mutex_lock(&m[j]); // DEADLOCK (false: m[i] and m[j] are indistinguishable to the analysis)
  pthread_mutex_unlock(&m[j]); // m[i] is still held, since i != j
  pthread_mutex_lock(&mutex1); // DEADLOCK
  g1 = g2 + 1;
  pthread_mutex_unlock(&mutex1);
  pthread_mutex_unlock(&m[i]);
  return NULL;
}

int main(int argc, char *argv[]) {
  pthread_t id;
  i = argc > 5;
  j = 1 - i;
  pthread_create(&id, NULL, t1, NULL);

  pthread_mutex_lock(&mutex1); // DEADLOCK
  pthread_mutex_lock(&m[i]); // DEADLOCK
  g2 = g1 + 1;
  pthread_mutex_unlock(&m[i]);
  pthread_mutex_unlock(&mutex1);

  pthread_join(id, NULL);
  printf("g1 = %d, g2 = %d.\n", g1, g2);
  return 0;
}
