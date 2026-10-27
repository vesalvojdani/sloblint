// Every pointer argument of the string functions must be valid (C11 7.24.1p2),
// also when a length argument is 0, so passing NULL is undefined behaviour.
#include <string.h>
#include <stdlib.h>

int main(void) {
  char buf[16] = "";
  char *n = NULL;
  int r;

  strcpy(buf, n); //WARN
  strcpy(n, "a"); //WARN
  strncpy(buf, n, 4); //WARN
  strcat(buf, n); //WARN
  strncat(buf, n, 0); //WARN
  r = strlen(n); //WARN
  strlen(n); //WARN
  r = strcmp(buf, n); //WARN
  r = strncmp(n, buf, 2); //WARN
  char *s = strstr(n, "a"); //WARN
  strstr(buf, n); //WARN

  char *m = rand() ? buf : NULL;
  strcpy(buf, m); //WARN

  strcpy(buf, NULL); //WARN
  void *vn = NULL;
  r = strlen(vn); //WARN

  char *v = "abc";
  strcpy(buf, v); //NOWARN
  strcat(buf, "x"); //NOWARN
  r = strlen(buf); //NOWARN
  r = strcmp(buf, v); //NOWARN
  s = strstr(buf, v); //NOWARN
  return 0;
}
