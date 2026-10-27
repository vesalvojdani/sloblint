// PARAM: --set ana.activated[+] 'maylocks' --set ana.activated[+] 'pthreadMutexType'
#define _GNU_SOURCE
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>

pthread_mutex_t mut1;
pthread_mutex_t mut2;
pthread_mutexattr_t normal;
uintptr_t attr_handle;
volatile int c = 0;

void* f1(void* ptr) {
    pthread_mutex_lock(&mut1);
    pthread_mutex_lock(&mut1); //WARN
    pthread_mutex_unlock(&mut1);
    return NULL; //WARN (mut1 is recursive and still held once)
}

void* f2(void* ptr) {
    pthread_mutex_lock(&mut2);
    pthread_mutex_lock(&mut2); //WARN
    pthread_mutex_unlock(&mut2);
    return NULL; //WARN (mut2 is recursive and still held once)
}

int main(void)
{
    pthread_t t1, t2;

    // The attribute is set through a pointer converted from an integer, whose target the analysis does not know, so it does not see the heap attribute written.
    pthread_mutexattr_t *pa = malloc(sizeof *pa);
    attr_handle = (uintptr_t)pa;
    pthread_mutexattr_init((pthread_mutexattr_t*)attr_handle);
    pthread_mutexattr_settype((pthread_mutexattr_t*)attr_handle, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&mut1, pa);

    // The same attribute or a known non-recursive one.
    pthread_mutexattr_init(&normal);
    pthread_mutexattr_settype(&normal, PTHREAD_MUTEX_NORMAL);
    pthread_mutex_init(&mut2, c ? &normal : pa);

    pthread_create(&t1, NULL, f1, NULL);
    pthread_join(t1, NULL);
    pthread_create(&t2, NULL, f2, NULL);
    pthread_join(t2, NULL);
    return 0;
}
