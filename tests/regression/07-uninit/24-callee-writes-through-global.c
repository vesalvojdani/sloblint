// PARAM: --set ana.activated[+] uninit
// Callees initialize locals of main whose address main stored into a global.
struct pair { int a; int b; };

int *gp;
struct pair *gs;

void init_gp(void) {
  *gp = 1;
}

int read_gp(void) {
  return *gp; // NOWARN
}

void init_a(void) {
  gs->a = 1;
}

int main(void) {
  int x;
  struct pair s;
  int r;

  gp = &x;
  init_gp();
  r = x; // NOWARN
  read_gp();

  gs = &s;
  init_a();
  r = s.a; // NOWARN
  r = s.b; // WARN
  return 0;
}
