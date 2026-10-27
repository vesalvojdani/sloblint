#include <pthread.h>

// A maximal sequence of adjacent bit-fields of non-zero width is one memory location (C11 3.14).

struct Adjacent { unsigned x : 3; unsigned y : 29; unsigned z; };
struct Adjacent adjacent;

// One memory location although a and b do not fit into one unsigned int.
struct Wide { unsigned a : 30; unsigned b : 30; };
struct Wide wide;

// Unnamed bit-fields of non-zero width belong to the sequence.
struct Unnamed { unsigned : 2; unsigned x : 3; unsigned y : 3; };
struct Unnamed unnamed;

// A zero-width bit-field ends the sequence.
struct ZeroWidth { unsigned x : 3; unsigned : 0; unsigned y : 29; };
struct ZeroWidth zero_width;

// A member which is not a bit-field ends the sequence.
struct Member { unsigned x : 3; char c; unsigned y : 4; };
struct Member member;

// A bit-field in a nested structure is a separate memory location.
struct Nested { struct { unsigned x : 3; } in; unsigned y : 5; };
struct Nested nested;

struct Unknown { unsigned x : 3; unsigned y : 5; };
extern struct Unknown *get_unknown();

void *t_fun(void *arg) {
  adjacent.x = 1; // RACE!
  wide.a = 1; // RACE!
  unnamed.x = 1; // RACE!
  zero_width.x = 1; // NORACE
  member.x = 1; // NORACE
  nested.in.x = 1; // NORACE
  get_unknown()->x = 1; // RACE!
  return NULL;
}

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  adjacent.y = 5; // RACE!
  adjacent.z = 5; // NORACE
  wide.b = 5; // RACE!
  unnamed.y = 5; // RACE!
  zero_width.y = 5; // NORACE
  member.y = 5; // NORACE
  nested.y = 5; // NORACE
  get_unknown()->y = 5; // RACE!
  pthread_join(id, NULL);
  return 0;
}
