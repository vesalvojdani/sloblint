// PARAM: --set ana.activated[+] expsplit --disable verify
#include <goblint.h>

// expsplit keeps one path per value of k, and k is computed from xs. The path
// k == 0 has xs == &a on entry and xs == &b after one iteration, since
// k = 0 | (&a == &b) = 0. Joined, xs == &b is unknown, so the transfer of the
// joined path moves its successor to the path where k is unknown. When
// narrowing shrinks the path k == 0 at the loop head back to xs == &a, its
// successor returns to k == 0 with xs == &b: the right-hand side grows during
// narrowing, and the path k == 0 keeps xs == &a alone, so the check below is
// reported as succeeding on it. The path where k is unknown still holds
// xs == &b, so the check is unknown overall.
// The stored value at the loop head is not above its right-hand side, which
// verification reports as "Fixpoint not reached", so it is disabled.

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
