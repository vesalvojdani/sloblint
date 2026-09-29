// PARAM: --set ana.activated[+] vla --disable warn.deadcode
#include <setjmp.h>
#include <stdlib.h>

jmp_buf env_buffer;

// A length containing the sizeof of a variable-length array is not an integer constant expression,
// so the array it bounds is a variable-length array too (C11 6.7.6.2p4).
void bound(int n) {
  int a[sizeof(int[n])];
  if (setjmp(env_buffer)) { // WARN
    return;
  }
}

void nested(int n) {
  int b[2][sizeof(int[sizeof(int[n])])];
  if (setjmp(env_buffer)) { // WARN
    return;
  }
}

int main(void) {
  int n = rand() % 3 + 1;
  {
    // Alignments, and sizes of fixed-size arrays, are integer constant expressions.
    int d[sizeof(int[4])];
    int e[_Alignof(int[n])];
    if (setjmp(env_buffer)) { // NOWARN
      return 0;
    }
  }
  bound(n);
  nested(n);
  return 0;
}
