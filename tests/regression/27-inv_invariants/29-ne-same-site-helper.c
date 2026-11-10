#include <stdlib.h>
#include <goblint.h>

int *new_int(void) { return malloc(sizeof(int)); }

int main(void) {
  int *p = new_int();
  int *q = new_int(); // a second block from the same allocation site
  if (p == NULL || q == NULL)
    return 0;
  if (p != q)
    __goblint_check(1); // reachable
  return 0;
}
