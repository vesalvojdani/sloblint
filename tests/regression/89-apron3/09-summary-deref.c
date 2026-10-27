// SKIP PARAM: --set ana.activated[+] apron
// Dereferences of pointers to a variable for which IsMultiple holds must not be
// read as that variable's relational variable: it stands for several cells.
#include <goblint.h>
#include <stdlib.h>

int *make(int v) {
  int *p = malloc(sizeof(int));
  *p = v;
  return p;
}

// Both blocks come from the malloc in make, so one heap variable stands for both.
void alloc(void) {
  int *a = make(3);
  int *b = make(7);
  int d = *a; // 3
  __goblint_check(d == *b); // UNKNOWN (3 == 7 is false)
  int e = *a - *b; // -4
  __goblint_check(e == -4); // UNKNOWN (true, but not known to the analysis)
}

// f(2, 0) calls f(1, &x), so in the inner call x stands for both copies of x.
void f(int n, int *parent) {
  int x = n;
  if (parent) {
    int d = x; // 1, the inner copy
    __goblint_check(d == *parent); // UNKNOWN (1 == 2 is false)
    int e = *parent - x; // 2 - 1
    __goblint_check(e == 1); // UNKNOWN (true, but not known to the analysis)
  } else {
    f(1, &x);
  }
}

// A dereference of a pointer to a variable that stands for one cell is still
// read relationally.
void single(void) {
  int y = rand();
  int *p = &y;
  int z = *p;
  __goblint_check(z == y);
}

// With the default ana.malloc.unique_address_count 0, the heap variable of this
// malloc is multiple although it is executed once, so *a is not read relationally.
void single_alloc(void) {
  int *a = malloc(sizeof(int));
  *a = rand();
  int d = *a;
  __goblint_check(d == *a); // TODO
}

int main(void) {
  alloc();
  f(2, 0);
  single();
  single_alloc();
  return 0;
}
