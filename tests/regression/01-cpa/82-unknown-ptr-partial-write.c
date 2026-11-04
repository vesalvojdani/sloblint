#include <goblint.h>
#include <string.h>

int main(void) {
  int c = 0;
  int d = 0;
  int *cp = &c;
  unsigned char buf[sizeof cp];
  memcpy(buf, &cp, sizeof cp);
  int *q;
  memcpy(&q, buf, sizeof q); // q is read back as an unknown pointer (or NULL)
  if (q != NULL) {
    // q points only to an unknown address.
    *q = 5; // WARN (assignment to unknown address)
    __goblint_check(c == 0); // TODO UNKNOWN (the execution writes 5 to c)

    int r;
    int *p = r ? q : &d; // p may point to d or to an unknown address

    // The write to the unknown address is dropped, which is an assumption and must be reported.
    *p = 7; // WARN (assignment to unknown address)
    __goblint_check(c == 0); // TODO UNKNOWN (the execution writes 7 to c when r is non-zero)
    __goblint_check(d == 0); // UNKNOWN

    // Refining *p is not a write of the program and reports no assumption.
    if (*p == 8) { // NOWARN
      d = 1;
    }
  }
  return 0;
}
