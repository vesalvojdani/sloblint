// Copying a pointer to a local into another local that has already escaped
// escapes the first local too.
#include <goblint.h>
#include <pthread.h>
#include <string.h>

int **gpp;

void *t_fun(void *arg) {
  **gpp = 7;
  return NULL;
}

int main(void) {
  int x = 5;
  int *p = &x;
  int *q = NULL;
  gpp = &q;
  memcpy(&q, &p, sizeof p);

  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  pthread_join(id, NULL);

  __goblint_check(x == 5); // UNKNOWN!
  return 0;
}
