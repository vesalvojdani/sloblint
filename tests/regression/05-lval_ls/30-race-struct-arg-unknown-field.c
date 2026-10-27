// A struct passed by value to a function without a definition reaches the objects of the type an unknown pointer stored in it points to.
#include <pthread.h>

struct t { int x; };
struct s { struct t *q; };

void ext(struct s a);
struct t *unknown_t(void);

struct t gt;

void *t_fun(void *arg) {
  gt.x = 1; // RACE!
  return NULL;
}

int main() {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  struct s v;
  v.q = unknown_t();
  ext(v); // RACE!
  return 0;
}
