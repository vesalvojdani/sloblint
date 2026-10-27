// PARAM: --set ana.activated[+] uninit
// Callees read uninitialized locals of their callers through pointers stored in globals.
#include <stdlib.h>

struct cell { int *p; };

int *gp;
int *gq;
struct cell *gc;

int read_gp(void) {
  return *gp; // WARN
}

int read_gp_nested(int unused) {
  return read_gp();
}

int read_gq(void) {
  return *gq; // WARN
}

void store_gq(int *p) {
  gq = p;
}

int read_gc(void) {
  return *gc->p; // WARN
}

// The inner activation of recurse leaves the outer w as it was.
int recurse(int depth) {
  int w;
  gp = &w;
  if (depth) {
    recurse(0);
    return w; // WARN
  }
  return 0;
}

int main(void) {
  int x, y, z;

  gp = &x;
  read_gp_nested(0);

  store_gq(&y);
  read_gq();

  gc = malloc(sizeof(struct cell));
  gc->p = &z;
  read_gc();

  recurse(1);
  return 0;
}
