// PARAM: --enable ana.float.interval
// Reading the bytes of float, double and long double array elements through
// pointers to integer types reinterprets them; it does not give the stored
// value converted to the integer type. The values in the comments are those
// of the IEEE 754 formats on a little-endian target.
#include <goblint.h>

int main() {
  double a[2] = {1.5, 1.5}; // 0x3ff8000000000000
  unsigned char *c = (unsigned char *)a;
  unsigned char c0 = *c;
  __goblint_check(c0 == 0); // UNKNOWN
  unsigned char c7 = c[7];
  __goblint_check(c7 == 0x3f); // UNKNOWN
  if (c7 == 0x3f)
    __goblint_check(1); // reachable

  signed char *sc = (signed char *)a;
  signed char s0 = sc[0];
  __goblint_check(s0 == 0); // UNKNOWN

  short *sh = (short *)a;
  short h3 = sh[3];
  __goblint_check(h3 == 0x3ff8); // UNKNOWN

  int *ip = (int *)a;
  int i0 = *ip;
  __goblint_check(i0 == 0); // UNKNOWN

  long long *lp = (long long *)a;
  long long l1 = lp[1];
  __goblint_check(l1 == 0x3ff8000000000000LL); // UNKNOWN
  if (l1 == 0x3ff8000000000000LL)
    __goblint_check(1); // reachable

  float f[2] = {2.0f, 2.0f}; // 0x40000000
  unsigned char *d = (unsigned char *)f;
  unsigned char d3 = d[3];
  __goblint_check(d3 == 0x40); // UNKNOWN
  int *fi = (int *)f;
  int fi1 = fi[1];
  __goblint_check(fi1 == 0x40000000); // UNKNOWN

  long double ld[2] = {1.0L, 1.0L}; // the lowest four bytes are 0
  unsigned char *e = (unsigned char *)ld;
  unsigned char e0 = e[0];
  __goblint_check(e0 == 0); // UNKNOWN
  int *li = (int *)ld;
  int li0 = *li;
  __goblint_check(li0 == 0); // UNKNOWN

  __goblint_check(a[1] == 1.5);
  __goblint_check(f[0] == 2.0f);
  return 0;
}
