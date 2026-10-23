// PARAM: --enable ana.float.interval
// A pointer to a malloc'd double or float keeps its target when it is
// converted to void * and back, so the object can be read through the
// converted pointer and freed through void *. Converting the float pointer,
// or a void * converted from it, on to a pointer to an integer type still
// gives the unknown pointer.
#include <stdlib.h>
#include <goblint.h>

int main(void) {
  double *d = malloc(sizeof(double));
  *d = 1.5;
  void *p = d;
  double *d2 = p;
  __goblint_check(*d2 > 1.0);
  long *l = p;
  __goblint_check(*l == 1); //UNKNOWN!
  free(p); //NOWARN

  float *f = malloc(sizeof(float));
  *f = 2.5f;
  void *q = f;
  float *f2 = q;
  __goblint_check(*f2 > 2.0f);
  free(f); //NOWARN

  // A block without a type converted to double * is typed double only in
  // that pointer: converting the untyped void * again, to long *, types it
  // long, and Base reads the stored double converted to long. The execution
  // reinterprets the bytes of 1.5 instead; reading through an incompatible
  // type is undefined behaviour (C11 6.5p7), which Base assumes absent.
  void *g = malloc(sizeof(double));
  double *h = g;
  *h = 1.5;
  long *a = g;
  __goblint_check(*a == 1); //TODO UNKNOWN!
  return 0;
}
