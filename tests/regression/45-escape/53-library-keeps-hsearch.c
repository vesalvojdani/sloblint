// hsearch's hash table keeps the key and data pointers of the item it enters,
// and the thread gets &x back from it: x escapes at the hsearch call.
#include <pthread.h>
#include <search.h>
#include <stdlib.h>

struct S { int f; };

void *reader(void *arg) {
  ENTRY q = { .key = "k", .data = NULL };
  ENTRY *e = hsearch(q, FIND);
  if (e) {
    struct S *p = e->data;
    p->f = 1; // RACE!
  }
  return NULL;
}

int main() {
  struct S x = {0};
  hcreate(8);
  ENTRY item = { .key = "k", .data = &x };
  hsearch(item, ENTER);
  pthread_t t;
  pthread_create(&t, NULL, reader, NULL);
  x.f = 2; // RACE!
  pthread_join(t, NULL);
  return 0;
}
