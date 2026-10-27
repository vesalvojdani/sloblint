// PARAM: --set ana.activated[+] uninit --enable exp.single-threaded --disable warn.unknown
// As 23, under exp.single-threaded. Base warns at the dereference of gp in read_gp that gp points to a non-local variable;
// warn.unknown is disabled so that WARN only matches the uninit warning.
int *gp;

int read_gp(void) {
  return *gp; // WARN
}

int main(void) {
  int x;
  gp = &x;
  read_gp();
  return 0;
}
