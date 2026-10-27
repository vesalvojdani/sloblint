#include <pthread.h>
#include <sys/select.h>
#include <stddef.h>

// pselect writes its fd sets, so two threads passing the same set race.

fd_set g;

void *t_fun(void *arg) {
  struct timespec t = { 0, 0 };
  pselect(1, &g, NULL, NULL, &t, NULL); // RACE!
  return NULL;
}

int main() {
  pthread_t id;
  FD_SET(0, &g);
  pthread_create(&id, NULL, t_fun, NULL);
  struct timespec t = { 0, 0 };
  pselect(1, &g, NULL, NULL, &t, NULL); // RACE!
  pthread_join(id, NULL);
  return 0;
}
