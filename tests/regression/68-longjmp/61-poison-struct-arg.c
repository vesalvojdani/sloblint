// A function without a definition may modify x through the pointer in a struct passed by value, so x is indeterminate after longjmp.
#include <setjmp.h>

struct s { int *p; };
void ext(struct s a);
void ext_ptr(int *p);

jmp_buf env_buffer;

int main() {
  int x = 0;
  int y = 0;
  int z = 0;
  struct s v;
  v.p = &x;
  if (setjmp(env_buffer)) {
    int a = x; //WARN
    int b = y; //WARN
    int c = z; //NOWARN
    return 0;
  }
  ext(v);
  ext_ptr(&y);
  longjmp(env_buffer, 1);
}
