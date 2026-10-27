// PARAM: --set ana.activated[+] 'maylocks' --set ana.activated[+] 'pthreadMutexType'
#include <pthread.h>
#include <stdio.h>

pthread_mutex_t m[2] = {PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER};
int i, j;

void *exit_holding(void *arg) {
  pthread_mutex_lock(&m[i]);
  pthread_mutex_lock(&m[j]); // WARN (false: m[i] and m[j] are indistinguishable to the analysis)
  pthread_mutex_unlock(&m[j]); // m[i] is still held, since i != j
  return NULL; // WARN
}

void *relock(void *arg) {
  pthread_mutex_lock(&m[i]);
  pthread_mutex_lock(&m[j]); // WARN (false: m[i] and m[j] are indistinguishable to the analysis)
  pthread_mutex_unlock(&m[j]); // m[i] is still held, since i != j
  pthread_mutex_lock(&m[i]); // WARN
  return NULL; // WARN
}

int main(int argc, char *argv[]) {
  pthread_t t1, t2;
  i = argc > 5;
  j = 1 - i;
  pthread_create(&t1, NULL, exit_holding, NULL);
  pthread_create(&t2, NULL, relock, NULL);
  return 0;
}
