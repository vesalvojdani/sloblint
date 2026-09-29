// PARAM: --set ana.activated[+] c2po --set ana.activated[+] startState --set ana.activated[+] taintPartialContexts
// fprintf writes through stderr, whose reachable addresses are unknown. As in
// base and the relational analyses, this does not invalidate the relation
// between the locals p and q, whose addresses are not taken.
#include <stdio.h>
#include <stdlib.h>
#include <goblint.h>

int main(void) {
  int *p = malloc(sizeof(int));
  int *q = p;
  fprintf(stderr, "x\n");
  __goblint_check(q == p);
  return 0;
}
