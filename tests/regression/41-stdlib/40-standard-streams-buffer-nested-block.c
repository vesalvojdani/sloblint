// CRAM
#include <stdio.h>

// A local declared in a nested block ends with the block, not at a return,
// which the analysis does not check, so the buffer is assumed to stay live.
// A local of the function's outermost block is checked at the return.
int main(void) {
  char outer[BUFSIZ];
  {
    char inner[BUFSIZ];
    setvbuf(stdin, inner, _IOFBF, sizeof inner);
    getchar();
    fclose(stdin);
  }
  setvbuf(stdout, outer, _IOFBF, sizeof outer);
  printf("a");
  return 0;
}
