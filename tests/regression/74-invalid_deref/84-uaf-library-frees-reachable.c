//PARAM: --set ana.activated[+] useAfterFree
// A library function whose specification has a deep free access frees the
// objects reachable from the object its argument points to. xdr_free frees the
// members of *objp, not *objp.
#include <stdlib.h>
#include <pthread.h>

typedef int (*xdrproc_t)(void);
extern void xdr_free(xdrproc_t proc, char *objp);
extern int xdr_msg(void);

struct msg { char *name; };

void members() {
  struct msg *m = malloc(sizeof(struct msg));
  m->name = malloc(8);
  char *name = m->name;
  xdr_free(xdr_msg, (char *) m);
  name[0] = 'x'; // WARN
  free(m); // NOWARN
}

// A shallow free access is the destruction of an object in place, not the
// deallocation of its block.
void destroy() {
  pthread_mutex_t *mutex = malloc(sizeof(pthread_mutex_t));
  pthread_mutex_init(mutex, NULL);
  pthread_mutex_destroy(mutex);
  free(mutex); // NOWARN
}

int main() {
  members();
  destroy();
  return 0;
}
