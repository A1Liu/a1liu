#include <stdio.h>

#include "debug_allocator.h"

int main(int argc, char **argv) {
  void *hello = malloc(16);
  check(hello);
  free(hello);
  free(hello);

  return 0;
}
