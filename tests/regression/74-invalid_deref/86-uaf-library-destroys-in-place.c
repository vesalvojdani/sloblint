//PARAM: --set ana.activated[+] useAfterFree --set lib.activated[+] zlib
// regfree and inflateEnd release what the library allocated for the object they
// are given. They do not free the object, nor the buffers it points to.
#include <stdlib.h>
#include <regex.h>

typedef struct { char *next_in; char *next_out; void *state; } z_stream;
extern int inflateEnd(z_stream *strm);

void regex() {
  regex_t *re = malloc(sizeof(regex_t));
  regcomp(re, "a", 0);
  regfree(re);
  free(re); // NOWARN
}

void zlib() {
  char *in = malloc(8);
  char *out = malloc(8);
  z_stream strm;
  strm.next_in = in;
  strm.next_out = out;
  inflateEnd(&strm);
  out[0] = 'x'; // NOWARN
  free(in); // NOWARN
  free(out); // NOWARN
}

int main() {
  regex();
  zlib();
  return 0;
}
