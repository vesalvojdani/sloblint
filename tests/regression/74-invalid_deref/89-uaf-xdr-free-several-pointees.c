//PARAM: --set ana.activated[+] useAfterFree --set ana.malloc.unique_address_count 1
// CRAM
// The argument of xdr_free points to n1 or n2. If it points to n1, xdr_free
// frees n2 through n1->next, but useAfterFree records neither of the objects
// the argument points to, and declares the assumption instead (see the .t file).
#include <stdlib.h>

typedef int (*xdrproc_t)(void);
extern void xdr_free(xdrproc_t proc, char *objp);
extern int xdr_node(void);

struct node { int v; struct node *next; };

int main() {
  struct node *n1 = malloc(sizeof(struct node));
  struct node *n2 = malloc(sizeof(struct node));
  n2->next = NULL;
  n1->next = n2;
  struct node *p = rand() ? n1 : n2;
  xdr_free(xdr_node, (char *) p);
  n2->v = 1; // not reported, assumption declared
  return 0;
}
