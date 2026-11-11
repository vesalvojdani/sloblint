#include <stdlib.h>
#include <goblint.h>

int main(void) {
  int *blocks[2];
  for (int i = 0; i < 2; i++)
    blocks[i] = malloc(sizeof(int)); // one allocation site, two blocks
  int *p = blocks[0];
  int *q = blocks[1];
  if (p == NULL || q == NULL)
    return 0;
  int same = p == q ? 1 : 0;
  __goblint_check(same == 0); // UNKNOWN
  if (p != q)
    __goblint_check(1); // reachable
  return 0;
}
