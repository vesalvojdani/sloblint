// PARAM: --set ana.activated[+] uninit
// Threads read locals of the thread that created them, through a global and through the thread argument.
#include <pthread.h>

struct s { int a; int b; };

int *gp;
int *gq;

void *read_globals(void *arg) {
  int r = *gp; // WARN
  int q = *gq; // NOWARN
  return NULL;
}

void *read_arg(void *arg) {
  struct s *p = arg;
  int a = p->a; // NOWARN
  int b = p->b; // WARN
  return NULL;
}

int main(void) {
  int x, y;
  struct s s;
  pthread_t id1, id2;
  gp = &x;
  gq = &y;
  y = 1;
  s.a = 1;
  pthread_create(&id1, NULL, read_globals, NULL);
  pthread_create(&id2, NULL, read_arg, &s);
  pthread_join(id1, NULL);
  pthread_join(id2, NULL);
  return 0;
}
