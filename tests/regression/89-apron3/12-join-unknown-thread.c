// PARAM: --set ana.activated[+] apron --set ana.path_sens[+] threadflag --set ana.relation.privatization mutex-meet-tid
#include <pthread.h>
#include <goblint.h>

pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
int g;

void *t_fun(void *arg); // no definition: the thread runs an unknown function, which may return

int main(void) {
  pthread_t id;
  pthread_create(&id, NULL, t_fun, NULL);
  pthread_join(id, NULL);
  // Reading g under m must not be bot after joining the thread.
  pthread_mutex_lock(&m);
  if (g == 0)
    __goblint_check(1); // reachable
  __goblint_check(g == 0); //UNKNOWN!
  pthread_mutex_unlock(&m);
  __goblint_check(1); // reachable
  return 0;
}
