#include <goblint.h>
struct str{
    int a;
    char c;
};

int main(){
    struct str a;

    char* ca = (char*) &a;
    void *ptr = &ca[4];
    void *ptr2 = &a.c;

    int z = 1;

    // Alginment of struct fields, and thus result of the equality check here is implementation defined.
    if(ptr == ptr2){
        z = 1;
    } else {
        z = 2;
    }

    // According to the C standard (section 6.2.8 in the C11 standard),
    // the alignment of fields in structs is implementation defined.
    // Goblint analyzes for the struct layout of its target machine, on which c is at byte 4, as with GCC.
    __goblint_check(z==1);
}
