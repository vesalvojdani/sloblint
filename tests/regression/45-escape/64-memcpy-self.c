// Copying a struct that points to itself into a global escapes the struct.
#include <goblint.h>
#include <pthread.h>
#include <string.h>

struct node {
  struct node *next;
  int v;
};

struct node g;

void *t_fun(void *arg) {
  g.next->v = 7;
  return NULL;
}

int main(void) {
  struct node n;
  n.next = &n;
  n.v = 1;
  memcpy(&g, &n, sizeof n);

  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  pthread_join(id, NULL);

  __goblint_check(n.v == 1); // UNKNOWN!
  return 0;
}
