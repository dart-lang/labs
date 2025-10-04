#include <stdio.h>

int main() {
  int x = 0x7ff;
  if ((int)((short)x) != x) {
    printf("no\n");
  }
  return 0;
}
