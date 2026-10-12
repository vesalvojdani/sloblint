#define _GNU_SOURCE
#include <stdio.h>
#include <stdarg.h>
#include <wchar.h>
#include <err.h>
#include <signal.h>
#include <goblint.h>

extern char *gets(char *str); // removed from <stdio.h> in C11
extern int __overflow(FILE *stream, int ch);
extern wchar_t *__fgetws_chk(wchar_t *s, size_t size, int n, FILE *stream);

// Each call has a specification: it writes only what its arguments reach, so
// the global g keeps its value, which a function without a specification
// would invalidate.
int g;

void report(const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  vwarn(format, ap);
  __goblint_check(g == 1);
  va_end(ap);
}

int main(int argc, char **argv) {
  g = 1;
  char line[16];
  line[0] = 1;
  fgets_unlocked(line, sizeof line, stdin);
  __goblint_check(g == 1);
  __goblint_check(line[0] == 1); // UNKNOWN!
  line[0] = 1;
  gets(line);
  __goblint_check(g == 1);
  __goblint_check(line[0] == 1); // UNKNOWN!
  wchar_t wline[16];
  wline[0] = 1;
  __fgetws_chk(wline, sizeof wline, 16, stdin);
  __goblint_check(g == 1);
  __goblint_check(wline[0] == 1); // UNKNOWN!
  warnx("x");
  __goblint_check(g == 1);
  psignal(SIGINT, "x");
  __goblint_check(g == 1);
  report("x");

  // __overflow writes the character into the stream's buffer.
  struct { int x; } s = { 1 };
  __overflow((FILE *) &s, 'c');
  __goblint_check(s.x == 1); // UNKNOWN!

  // err and errx do not return.
  if (argc > 1) {
    err(1, "x");
    __goblint_check(0); // NOWARN (unreachable)
  }
  if (argc > 2) {
    errx(1, "x");
    __goblint_check(0); // NOWARN (unreachable)
  }
  return 0;
}
