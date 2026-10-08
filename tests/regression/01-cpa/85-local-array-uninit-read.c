// PARAM: --enable annotation.goblint_array_domain
// The elements of a local array that uses the trivial array domain start without a value,
// and after the first write to an element the domain no longer records which elements were written.
// A read of an element relies on the elements being written before they are read,
// and declares this assumption.
#include <stddef.h>

struct obj { int state; };
struct obj o;
struct obj *g[2];

int main(void) {
  struct obj *a[2];
  for (int i = 1; i < 2; i++)
    a[i] = &o;
  // a[0] is never written.
  for (int i = 0; i < 2; i++) {
    struct obj *p = a[i]; // WARN (assumption: a[0] is read before it is written)
  }
  struct obj **pa = a;
  struct obj *p1 = pa[1]; // WARN (assumption: read through a pointer to an element)

  struct obj *b[2];
  // No element of b is written.
  int s = b[1]->state; // WARN (assumption: b[1] is dereferenced before it is written)

  // Read on its own, the missing int becomes an unknown int.
  int c[2];
  int x = c[0]; // NOWARN

  struct obj *h = g[0]; // NOWARN (global arrays are initialized)

  struct obj *d[2] __attribute__((goblint_array_domain("partitioned")));
  d[1] = &o;
  struct obj *q = d[1]; // NOWARN (the partitioned domain starts elements as unknown values)
  return 0;
}
