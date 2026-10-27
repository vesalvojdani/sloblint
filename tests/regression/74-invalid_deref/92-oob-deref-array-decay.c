// PARAM: --set ana.activated[+] memOutOfBounds --enable ana.int.interval
// Dereferences of pointer arithmetic on an array that decays to a pointer: no variable involved is a pointer.
int main() {
  int k[4];
  *(k + 3) = 1; // NOWARN
  *(k + 5) = 1; // WARN
  int x = *(k + 5); // WARN

  return 0;
}
