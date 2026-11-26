//PARAM: --set ana.activated[+] useAfterFree --set ana.malloc.unique_address_count 1
// CRAM
// The object and the buffer are allocated at different sites, each a unique
// block, so getline declares no assumption (see the .t file) and the stale
// pointer to the buffer is reported.
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

struct ctx { char *line; size_t n; };

int main() {
  struct ctx *c = malloc(sizeof(struct ctx));
  c->n = 2;
  c->line = malloc(c->n);
  char *old = c->line;
  if (getline(&c->line, &c->n, stdin) < 0) return 0;
  old[0] = 'x'; // WARN
  return 0;
}
