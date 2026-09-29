// CRAM
#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>

// The end of a stream buffer's storage is not checked, so every buffer but
// static storage is assumed to stay live while the stream uses it: a local,
// heap memory, and a buffer handed to a stream from fopen. Giving a stream no
// buffer needs no assumption.
static char global_buffer[BUFSIZ];

int main(void) {
  char local[BUFSIZ];
  setvbuf(stdout, global_buffer, _IOFBF, sizeof global_buffer);
  setvbuf(stdout, local, _IOFBF, sizeof local);
  setbuffer(stdout, NULL, 0);
  char *heap = malloc(BUFSIZ);
  setbuf(stderr, heap);
  FILE *f = fopen("/dev/null", "w");
  if (f) {
    setvbuf(f, local, _IOFBF, sizeof local);
    fclose(f);
  }
  return 0;
}
