// PARAM: --set ana.activated[+] 'maylocks' --set ana.activated[+] 'pthreadMutexType'
#define _GNU_SOURCE
#include <pthread.h>
#include <stdint.h>

// Defined in another translation unit, which may set any mutex type in it.
extern pthread_mutexattr_t *shared_attr;

pthread_mutex_t mut1;
pthread_mutex_t mut2;
pthread_mutexattr_t attr;
uintptr_t attr_handle;

void* f1(void* ptr) {
    pthread_mutex_lock(&mut1);
    pthread_mutex_lock(&mut1); //WARN
    pthread_mutex_unlock(&mut1);
    return NULL; //WARN (mut1 may be recursive and still held once)
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

    pthread_mutex_init(&mut1, shared_attr);

    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    // The analysis does not know the target of a pointer converted from an integer.
    attr_handle = (uintptr_t)&attr;
    pthread_mutex_init(&mut2, (pthread_mutexattr_t*)attr_handle);

    pthread_create(&t1, NULL, f1, NULL);
    pthread_join(t1, NULL);
    pthread_create(&t2, NULL, f2, NULL);
    pthread_join(t2, NULL);
    return 0;
}
