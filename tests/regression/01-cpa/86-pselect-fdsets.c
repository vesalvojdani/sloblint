#include <goblint.h>
#include <sys/select.h>
#include <stddef.h>

// pselect, like select, overwrites each fd set with the subset of its file
// descriptors that are ready, so a bit set before the call may be cleared.

void test_pselect() {
  fd_set r = { { [0 ... FD_SETSIZE / NFDBITS - 1] = ~0 } }; // every bit set
  fd_set w = r;
  fd_set e = r;
  struct timespec t = { 0, 0 };
  __goblint_check(FD_ISSET(0, &r));
  __goblint_check(FD_ISSET(0, &w));
  __goblint_check(FD_ISSET(0, &e));
  pselect(1, &r, &w, &e, &t, NULL);
  __goblint_check(FD_ISSET(0, &r)); // UNKNOWN!
  __goblint_check(FD_ISSET(0, &w)); // UNKNOWN!
  __goblint_check(FD_ISSET(0, &e)); // UNKNOWN!
  __goblint_check(t.tv_sec == 0); // pselect does not modify its timeout
}

void test_select() {
  fd_set r = { { [0 ... FD_SETSIZE / NFDBITS - 1] = ~0 } }; // every bit set
  fd_set w = r;
  fd_set e = r;
  struct timeval t = { 0, 0 };
  select(1, &r, &w, &e, &t);
  __goblint_check(FD_ISSET(0, &r)); // UNKNOWN!
  __goblint_check(FD_ISSET(0, &w)); // UNKNOWN!
  __goblint_check(FD_ISSET(0, &e)); // UNKNOWN!
}

int main() {
  test_pselect();
  test_select();
  return 0;
}
