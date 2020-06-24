#include <stdio.h>

#include "debug_allocator.h"

struct Hello {
  unsigned int world;
};

int main(int argc, char **argv) {
  struct Hello *hello = malloc(16);
  check(hello)->world = 0;
  check(NULL);
  free(hello);

  return 0;
}
