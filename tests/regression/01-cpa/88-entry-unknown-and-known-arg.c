// A callee may write the caller's local through a pointer argument that may also be an unknown pointer.
#include <goblint.h>

int *unknown_ptr(void);

void store(int *q, int c) {
  if (c)
    *q = 5;
}

int main() {
  int c, d; // unknown
  int x = 7;
  int *q;
  if (d)
    q = &x;
  else
    q = unknown_ptr();
  store(q, c);
  __goblint_check(x == 5); // UNKNOWN!
  __goblint_check(x == 7); // UNKNOWN!
  return 0;
}
