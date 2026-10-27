#include <goblint.h>
#include <string.h>

// A pointer to a struct whose first member is a bit-field, converted to a
// pointer to a type no bigger than the struct, points to the storage unit that
// holds the bit-field (C11 6.7.2.1p15). The unit also holds the bit-fields that follow,
// so accesses through the converted pointer read and write all of them. No
// offset denotes the unit, so the values read back are unknown.

struct B { unsigned x : 3; unsigned y : 29; unsigned z; };
struct C { unsigned char lo : 4; unsigned char hi : 4; int z; };
struct O { struct B in; int z; };
struct S { unsigned x : 3; unsigned y : 29; };
struct D { unsigned char lo : 4; unsigned char hi : 4; unsigned char d; int z; };

int main(void) {
  // write the whole unit through the converted pointer
  struct B b = {0, 0, 0};
  unsigned *p = (unsigned *)&b;
  *p = 0xFFFFFFFFu;
  __goblint_check(b.x == 7); // UNKNOWN
  __goblint_check(b.y == 0x1FFFFFFF); // UNKNOWN

  // read the whole unit through the converted pointer
  b.x = 1;
  b.y = 1;
  unsigned v = *p;
  __goblint_check(v != 1); // UNKNOWN

  // character access to the unit holding two bit-fields
  struct C c = {0, 0, 0};
  unsigned char *q = (unsigned char *)&c;
  *q = 0xFF;
  __goblint_check(c.lo == 15); // UNKNOWN
  __goblint_check(c.hi == 15); // UNKNOWN

  // the bit-field is the first member of the first member
  struct O o = {{0, 0, 0}, 0};
  p = (unsigned *)&o;
  *p = 0xFFFFFFFFu;
  __goblint_check(o.in.y == 0x1FFFFFFF); // UNKNOWN

  // the unit is as big as the struct
  struct S s = {0, 0};
  p = (unsigned *)&s;
  *p = 0xFFFFFFFFu;
  __goblint_check(s.y == 0x1FFFFFFF); // UNKNOWN
  s.x = 1;
  s.y = 1;
  v = *p;
  __goblint_check(v != 1); // UNKNOWN

  // memset of the first byte through the converted pointer
  struct D d = {1, 2, 7, 9};
  q = (unsigned char *)&d;
  memset(q, 0, 1);
  __goblint_check(d.hi == 0); // UNKNOWN
  __goblint_check(d.d == 7); // UNKNOWN
  __goblint_check(d.z == 9); // UNKNOWN

  return 0;
}
