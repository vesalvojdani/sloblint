// Copying the bytes of a pointer into an integer with memcpy, and from the
// integer back into a pointer, keeps the address.
#include <stdint.h>
#include <string.h>
#include <goblint.h>

int main(void) {
  int value = 1;
  int *p = &value;
  uintptr_t i;
  memcpy(&i, &p, sizeof i);
  __goblint_check((int *)i == p);

  int *q;
  memcpy(&q, &i, sizeof q);
  __goblint_check(q == p);
  *q = 2;
  __goblint_check(value == 2);

  // into an integer of the same type
  uintptr_t k;
  memcpy(&k, &i, sizeof k);
  __goblint_check((int *)k == p);

  // into an integer of another type of the same size
  intptr_t j;
  memcpy(&j, &i, sizeof j);
  __goblint_check((int *)j == p);

  // the remainder of the integer is an unknown integer of its type
  int misaligned = 0;
  if (i % 4 != 0)
    misaligned = 1;
  __goblint_check(misaligned == 0); // UNKNOWN
  return 0;
}
