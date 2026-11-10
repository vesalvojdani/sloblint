// PARAM: --set witness.yaml.validate 84-base-lor-multiple-addr.yml
#include <stdlib.h>

int *new_int(void) { return malloc(sizeof(int)); }

int main() {
  int *p = new_int();
  int *q = new_int(); // a second block from the same allocation site
  ; // UNKNOWN! (witness)
  ; // UNKNOWN! (witness)
  return 0;
}
