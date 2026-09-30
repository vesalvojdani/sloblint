// PARAM: --enable ana.race.direct-arithmetic
// memset, strlen and printf keep no pointer to buf after they return, so buf
// does not escape, and the thread cannot reach it.
#include <pthread.h>
#include <stdio.h>
#include <string.h>

char *g;

void *writer(void *arg) {
  g[0] = 'y'; // NORACE
  return NULL;
}

int main() {
  char buf[4];
  char other[4];
  g = other;
  memset(buf, 'a', 3);
  buf[3] = 0;
  printf("%zu %s\n", strlen(buf), buf);
  pthread_t t;
  pthread_create(&t, NULL, writer, NULL);
  buf[0] = 'x'; // NORACE
  pthread_join(t, NULL);
  return 0;
}
