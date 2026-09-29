// CRAM
#include <stdio.h>

// Returning from main ends its local buffer before exit flushes stdout
// (C11 5.1.2.2.3): the flush reads the buffer after its lifetime.
int main(void) {
  char buffer[BUFSIZ];
  setvbuf(stdout, buffer, _IOFBF, sizeof buffer);
  printf("hello\n");
  return 0;
}
