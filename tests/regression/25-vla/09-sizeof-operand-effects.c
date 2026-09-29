#include <goblint.h>
#include <stdlib.h>

// sizeof evaluates its operand exactly when the operand's type is a variable-length array (C11 6.5.3.4p2).
int g;
int f(void) { g = 1; return 0; }
int h(void) { g = 2; return 1; }

int main(int argc, char **argv) {
  int n = argc + 1;
  int vla[n][n];
  int fixed[2][2];

  size_t s1 = sizeof(vla[f()]);
  __goblint_check(g == 1);

  int i = 0;
  size_t s2 = sizeof(vla[i++]);
  __goblint_check(i == 1);

  // A type name of variable-length array type is evaluated too.
  size_t count = 10;
  size_t s3 = sizeof(int[count++]);
  __goblint_check(count == 11);

  // A fixed-size operand and the operand of __alignof__ are not evaluated.
  size_t s4 = sizeof(fixed[h()]);
  size_t s5 = sizeof(vla[h()][0]);
  size_t s6 = __alignof__(vla[h()]);
  size_t s7 = sizeof(int (*)[h()]);
  size_t s8 = sizeof(i++);
  __goblint_check(g == 1);
  __goblint_check(i == 1);
  return 0;
}
