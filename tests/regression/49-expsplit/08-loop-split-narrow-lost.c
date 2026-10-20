// PARAM: --set ana.activated[+] expsplit
#include <goblint.h>

// As in 07-loop-split-narrow.c, the path k == 0, j == 0 at the loop head holds
// xs == &a and xs == &b during widening, the transfer of the joined path moves
// its successor to the path k unknown, j == 0, and when narrowing shrinks the
// path k == 0, j == 0 back to xs == &a, its successor xs == &b returns to it.
// If the solver narrows anyway, that state is dropped from the path k == 0,
// j == 0. Unlike in 07, no other path keeps it: the path k unknown, j == 0
// receives nothing once the path k == 0, j == 0 is narrowed (its own successor
// has j unknown), so narrowing removes it, and the remaining path k unknown,
// j unknown only has p == 1. The check below would then be reported as
// succeeding, although it fails in the second iteration.

struct node { struct node *next; };

int main(void) {
  struct node a, b;
  a.next = &b;
  b.next = &a;
  struct node *xs = &a;
  int k = 0, j = 0;
  int p = 0, q = 0; // p == 0 exactly in the first two iterations
  __goblint_split_begin(k);
  __goblint_split_begin(j);
  while (1) {
    // The second iteration reaches here with k == 0, j == 0, xs == &b and p == 0.
    __goblint_check(xs == &a || p == 1); // UNKNOWN!
    int t = (xs == &b);
    j = k;
    k = k | t;
    p = q;
    q = 1;
    xs = xs->next;
  }
  return 0;
}
