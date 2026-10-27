// SKIP PARAM: --set ana.activated[+] apron --enable ana.sv-comp.functions
// Copying a pointer to a local into a global with memcpy escapes the local,
// so the relation between the local and another one is lost when a callee
// writes the local through the global.
#include <goblint.h>
#include <string.h>

extern int __VERIFIER_nondet_int(void);

static int *target;

static void modify(void) {
  *target = __VERIFIER_nondet_int();
}

int main(void) {
  int left = __VERIFIER_nondet_int();
  int right = left;
  int *source = &right;
  memcpy(&target, &source, sizeof(target));

  modify();
  __goblint_check(left == right); // UNKNOWN!
  return 0;
}
