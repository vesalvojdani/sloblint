// PARAM: --enable ana.race.direct-arithmetic
// register_buffer and registered_buffer have neither a definition nor a
// specification, so register_buffer may keep the pointer it is given, and
// the thread may get it back from registered_buffer: buf escapes at the
// register_buffer call.
#include <pthread.h>

void register_buffer(char *buf);
char *registered_buffer(void);

void *reader(void *arg) {
  char *s = registered_buffer();
  s[0] = 'y'; // RACE!
  return NULL;
}

int main() {
  char buf[4] = "abc";
  register_buffer(buf);
  pthread_t t;
  pthread_create(&t, NULL, reader, NULL);
  buf[0] = 'x'; // RACE!
  pthread_join(t, NULL);
  return 0;
}
