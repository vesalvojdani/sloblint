//PARAM: --set ana.activated[+] useAfterFree
// CRAM
// The object and the buffer in its field are allocated by the same call in
// xmalloc, so one heap variable stands for both. getline reallocates the
// buffer, but useAfterFree does not record the heap variable of the object the
// argument points to, and declares the assumption instead (see the .t file).
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

void *xmalloc(size_t n) {
  return malloc(n);
}

struct ctx { char *line; size_t n; };

int main() {
  struct ctx *c = xmalloc(sizeof(struct ctx));
  c->n = 2;
  c->line = xmalloc(c->n);
  char *old = c->line;
  if (getline(&c->line, &c->n, stdin) < 0) return 0;
  old[0] = 'x'; // not reported, assumption declared
  return 0;
}
