// PARAM: --enable ana.race.direct-arithmetic
// putenv makes buf part of the environment without copying it, and the
// thread gets a pointer into buf back from getenv: buf escapes at the putenv
// call.
#include <pthread.h>
#include <stdlib.h>

void *reader(void *arg) {
  char *s = getenv("X");
  if (s)
    s[2] = 'y'; // RACE!
  return NULL;
}

int main() {
  char buf[] = "X=1";
  putenv(buf);
  pthread_t t;
  pthread_create(&t, NULL, reader, NULL);
  buf[2] = '2'; // RACE!
  pthread_join(t, NULL);
  return 0;
}
