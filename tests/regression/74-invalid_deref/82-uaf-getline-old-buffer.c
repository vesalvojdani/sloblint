//PARAM: --set ana.activated[+] useAfterFree
// getline calls realloc on *lineptr when the line does not fit.
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

void local() {
  size_t n = 2;
  char *buf = malloc(n);
  char *old = buf;
  if (getline(&buf, &n, stdin) < 0) return;
  old[0] = 'x'; // WARN
}

// The object that holds the buffer pointer is not freed.
struct ctx { char *line; size_t n; int other; };

void field() {
  struct ctx *c = malloc(sizeof(struct ctx));
  c->n = 2;
  c->line = malloc(c->n);
  char *old = c->line;
  if (getline(&c->line, &c->n, stdin) < 0) return;
  c->other = 2; // NOWARN
  old[0] = 'x'; // WARN
  free(c); // NOWARN
}

int main() {
  local();
  field();
  return 0;
}
