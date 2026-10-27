// PARAM: --disable warn.behavior
// From goblint/analyzer#2106: both structs share one blob, whose mem field is lost, so head->mem is an unknown pointer.
#include <goblint.h>
#include <stdlib.h>
void *safe_malloc(size_t size) {
  void *p = malloc(size);
  if (p == 0) {
    abort();
  }
  return p;
}


struct mem {
    int val;
};

struct list_node {
    struct mem *mem;
};

int main() {
    struct mem *m = safe_malloc(sizeof(*m));
    m->val = 100;

    struct list_node *head = safe_malloc(sizeof(*head));
    head->mem = m;

    head->mem->val += 100; // WARN (assignment to unknown address)
    __goblint_check(m->val > 90 && m->val < 110); // TODO UNKNOWN (the execution sets m->val to 200, so the check fails)
}
