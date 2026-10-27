// Copying a pointer to a local into a global with memcpy escapes the local.
#include <goblint.h>
#include <pthread.h>
#include <string.h>

static int *target;

static void *modify(void *arg) {
  *target = 7;
  return NULL;
}

int main(void) {
  int right = 42;
  int *source = &right;
  memcpy(&target, &source, sizeof(target));

  pthread_t thread;
  pthread_create(&thread, NULL, modify, NULL);
  pthread_join(thread, NULL);

  __goblint_check(right == 42); // UNKNOWN!
  return 0;
}
