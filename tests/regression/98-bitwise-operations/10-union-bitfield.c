// PARAM: --enable ana.int.interval
// Reads and writes of bit-field members of unions.
// Which bits of its storage unit a bit-field occupies is implementation-defined (C11 6.7.2.1p11),
// so a value stored through one member does not determine the value of a bit-field member, nor the other way round.
#include <goblint.h>

union U {
  unsigned w;
  unsigned x : 3;
};

union S {
  int w;
  signed int x : 3;
};

union B {
  unsigned x : 3;
  unsigned y : 5;
};

union V {
  unsigned x : 3;
  unsigned w;
};

union U g;
union V h;

int main(int argc, char **argv) {
  // Read a bit-field after a write through a wider member: with GCC on x86, u.x is 1.
  union U u;
  u.w = 9;
  __goblint_check(u.x <= 7);
  __goblint_check(u.x == 1); // UNKNOWN!

  // The same for a signed bit-field: with GCC on x86, s.x is -1.
  union S s;
  s.w = 7;
  __goblint_check(s.x == -1); // UNKNOWN!

  // Write a value a bit-field cannot represent: an unsigned bit-field keeps the value modulo 8 (C11 6.3.1.3p2).
  union U v;
  v.x = 9; // WARN
  __goblint_check(v.x == 1); // TODO

  // Read a wider member after a write to a bit-field: the bits of v.w outside v.x keep their value with GCC on x86, so v.w is 0xF1.
  v.w = 0xF0;
  v.x = 1;
  __goblint_check(v.w == 1); // UNKNOWN!

  // Read another bit-field: with GCC on x86, b.x holds the low three bits of b.y.
  union B b;
  b.y = 9;
  __goblint_check(b.x == 1); // UNKNOWN!

  // Read a bit-field after writes through different members joined: with GCC on x86 and argc > 0, j.x is 1.
  union U j;
  if (argc > 0)
    j.w = 9;
  else
    j.x = 2;
  __goblint_check(j.x >= 2); // UNKNOWN!

  // A bit-field written last reads back as written.
  union U k;
  k.x = 5;
  __goblint_check(k.x == 5);

  // Writing 0 through a member of the union's size makes every bit zero.
  __goblint_check(g.x == 0);
  union U z = { 0 };
  __goblint_check(z.x == 0);
  // Static storage zeroes the bits of h.w outside h.x (C11 6.7.9p10), but a write to h.x would not.
  __goblint_check(h.w == 0); // TODO
  return 0;
}
