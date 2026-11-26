//PARAM: --set ana.activated[+] useAfterFree
// CRAM
// closedir and freeaddrinfo free memory that the analysis has no heap variable
// for, because the library allocated it. useAfterFree declares the assumption
// that this memory is not accessed afterwards (see the .t file).
#include <dirent.h>
#include <netdb.h>
#include <string.h>

int main() {
  DIR *d = opendir(".");
  if (!d) return 1;
  struct dirent *e = readdir(d);
  closedir(d);

  struct addrinfo hints, *res;
  memset(&hints, 0, sizeof hints);
  if (getaddrinfo("127.0.0.1", NULL, &hints, &res) != 0) return 1;
  freeaddrinfo(res);
  return 0;
}
