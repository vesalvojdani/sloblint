#include <pthread.h>
#include <stdlib.h>

// The members of a union overlap, so accesses to different members may race.

union Same { int a; int b; };
union Same same;

// Members of different sizes overlap in their first byte.
union Sizes { char c; long l; };
union Sizes sizes;

// Bit-fields of a union overlap as well.
union Bits { unsigned a : 3; unsigned b : 5; };
union Bits bits;

// An anonymous union in a structure: k does not overlap the union.
struct Anon { int k; union { int a; float f; }; };
struct Anon anon, anon2;

// The fields of a structure member may overlap the other members: x overlaps c, y does not.
union Inner { struct { int x; int y; } s; char c; };
union Inner inner, inner2, inner3;

// Nested unions.
union Nested { union { int i; short h; } in; long l; };
union Nested nested, nested2;

// A member before and a member after a structure member, accessed through an unknown pointer to the structure.
struct S1 { int x; int y; };
struct S2 { int x; int y; };
union Before { int a; struct S1 s; };
union After { struct S2 s; int z; };
union Before before;
union After after;
extern struct S1 *get_s1();
extern struct S2 *get_s2();

// Accesses through an unknown pointer to the union.
union Unknown { int a; int b; };
extern union Unknown *get_unknown();

union Heap { int a; int b; };
union Heap *heap;

void *t_fun(void *arg) {
  same.a = 1; // RACE!
  sizes.c = 1; // RACE!
  bits.a = 1; // RACE!
  anon.a = 1; // RACE!
  anon2.k = 1; // NORACE
  inner.s.x = 1; // RACE!
  inner2.s.x = 1; // NORACE
  inner3.s.y = 1; // RACE (no data race, because y does not overlap c)
  nested.in.i = 1; // RACE!
  nested2.in.i = 1; // RACE!
  before.a = 1; // RACE!
  after.z = 1; // RACE!
  get_unknown()->a = 1; // RACE!
  heap->a = 1; // RACE!
  return NULL;
}

int main(void) {
  heap = malloc(sizeof(union Heap));
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  same.b = 5; // RACE!
  sizes.l = 5; // RACE!
  bits.b = 5; // RACE!
  anon.f = 5; // RACE!
  anon2.f = 5; // NORACE
  inner.c = 5; // RACE!
  inner2.s.y = 5; // NORACE
  inner3.c = 5; // RACE
  nested.in.h = 5; // RACE!
  nested2.l = 5; // RACE!
  get_s1()->x = 5; // RACE!
  get_s2()->x = 5; // RACE!
  get_unknown()->b = 5; // RACE!
  heap->b = 5; // RACE!
  pthread_join(id, NULL);
  return 0;
}
