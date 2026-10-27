// Reading integers through a pointer to an array of a wider integer type.
// The index counts elements of the wider type, so (*v)[1] is made of s[2] and s[3], not s[1] converted to int.
#include <goblint.h>

int main() {
  short s[4] = {1, 1, 1, 1};
  int (*v)[2] = (int (*)[2])&s;
  int v0 = (*v)[0];
  __goblint_check(v0 == 0x10001); // UNKNOWN
  if (v0 == 0x10001)
    __goblint_check(1); // reachable
  int v1 = (*v)[1];
  __goblint_check(v1 == 0x10001); // UNKNOWN
  if (v1 == 0x10001)
    __goblint_check(1); // reachable

  unsigned char k[4] = {1, 1, 1, 1};
  unsigned short (*u)[2] = (unsigned short (*)[2])&k;
  unsigned short u1 = (*u)[1];
  __goblint_check(u1 == 0x0101); // UNKNOWN
  if (u1 == 0x0101)
    __goblint_check(1); // reachable

  int a[4] = {1, 1, 1, 1};
  long long (*l)[2] = (long long (*)[2])&a;
  long long l1 = (*l)[1];
  __goblint_check(l1 == 0x100000001LL); // UNKNOWN
  if (l1 == 0x100000001LL)
    __goblint_check(1); // reachable

  return 0;
}
