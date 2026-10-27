//PARAM: --set ana.malloc.unique_address_count 1 --set ana.activated[+] memLeak --enable sem.malloc.fail --set sem.malloc.zero pointer
#include <stdlib.h>
#include <goblint.h>

int main(int argc, char const *argv[]) {
    int *p = malloc(0); // under sem.malloc.zero pointer, the result is not the null pointer
    int x = 5;
    __goblint_check(x == 5);
    free(p);

    int *q = malloc(sizeof(int)); // under sem.malloc.fail, the result may be the null pointer
    if (q == NULL) {
        __goblint_check(1); // reachable
        return 1;
    }
    free(q);
    return 0; //NOWARN
}
