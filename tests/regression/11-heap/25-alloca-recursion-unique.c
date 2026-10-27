// PARAM: --set ana.malloc.unique_address_count 1
// The alloca of the inner call of rec allocates a block different from the one of the outer call.
#include <alloca.h>
#include <goblint.h>

int *outer;

void rec(int depth) {
  int *q = alloca(sizeof(int));
  *q = depth;
  if (depth == 0) {
    outer = q;
    rec(1);
    __goblint_check(*q == 0);
    __goblint_check(*outer == 0);
  } else {
    __goblint_check(q != outer);
    *q = 5;
  }
}

int main() {
  rec(0);
  return 0;
}
