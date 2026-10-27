// PARAM: --disable warn.imprecise --disable warn.unsound
// Library functions write through pointers that Goblint evaluates to {?, NULL}:
// each such write is declared as an assumption, and nothing else is reported at
// those lines once imprecision and unsoundness messages are disabled.
#include <goblint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void unknown_fn(int *p); // no definition

int main(void) {
  int a = 5, b = 5, c = 5, d = 5, w = 1;
  int *pa = &a, *pb = &b, *pc = &c, *pd = &d, *pw = &w;
  int *qa, *qb, *qc, *qd, *qw;
  unsigned char buf[sizeof(int *)];

  // Copying a pointer through a byte buffer gives {?, NULL}.
  memcpy(buf, &pa, sizeof pa);
  memcpy(&qa, buf, sizeof qa);
  memcpy(buf, &pb, sizeof pb);
  memcpy(&qb, buf, sizeof qb);
  memcpy(buf, &pc, sizeof pc);
  memcpy(&qc, buf, sizeof qc);
  memcpy(buf, &pd, sizeof pd);
  memcpy(&qd, buf, sizeof qd);
  memcpy(buf, &pw, sizeof pw);
  memcpy(&qw, buf, sizeof qw);

  // A specified argument written shallowly.
  __atomic_store_n(qa, 0, __ATOMIC_SEQ_CST); // WARN
  __goblint_check(a == 0); // TODO UNKNOWN

  // A variadic argument written shallowly.
  sscanf("7", "%d", qb); // WARN
  __goblint_check(b == 7); // TODO UNKNOWN

  // The lvalue a library call assigns its result to.
  *qc = atoi("7"); // WARN
  __goblint_check(c == 7); // TODO UNKNOWN

  // An argument of a function without definition, written deeply.
  unknown_fn(qd); // WARN
  __goblint_check(d == 5); // TODO UNKNOWN

  // A specified argument written shallowly, whose value is then unknown.
  if (read(0, qw, sizeof w) == sizeof w) // WARN
    __goblint_check(w == 1); // TODO UNKNOWN!

  // The same write through a known pointer assumes nothing.
  int e = 1;
  if (read(0, &e, sizeof e) == sizeof e) // NOWARN
    __goblint_check(e == 1); // UNKNOWN!

  return 0;
}
