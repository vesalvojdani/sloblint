// PARAM: --set ana.activated[+] expsplit
#include <goblint.h>

// expsplit keeps one path per value of k, and k is computed from xs. The path
// k == 0 has xs == &a on entry and xs == &b after one iteration, since
// k = 0 | (&a == &b) = 0. Joined, xs == &b is unknown, so the transfer of the
// joined path moves its successor to the path where k is unknown. When
// narrowing shrinks the path k == 0 at the loop head back to xs == &a, its
// successor returns to k == 0 with xs == &b: the right-hand side grows during
// narrowing. If the solver narrows anyway, it keeps xs == &a alone in the path
// k == 0, reports the check below as succeeding there, and reports
// "Fixpoint not reached".

struct node { struct node *next; };

int main(void) {
  struct node a, b;
  a.next = &b;
  b.next = &a;
  struct node *xs = &a;
  int k = 0;
  __goblint_split_begin(k);
  while (1) {
    __goblint_check(xs == &a || xs == &b);
    __goblint_check(xs == &a); // UNKNOWN!
    k = k | (xs == &b);
    xs = xs->next;
  }
  return 0;
}
