#include "hashtable.c"
#include <stdio.h>

int main() {
  Hash hash = hash_new(12, sizeof(uint32_t));

  uint32_t *loc = hash_insert(&hash, 0, sizeof(uint32_t));
  *loc = 12;

  loc = hash_find(&hash, 0, sizeof(uint32_t));

  printf("%u\n", *(uint32_t *)hash_remove(&hash, 0, sizeof(uint32_t)));
  printf("%lu\n", (size_t)hash_find(&hash, 0, sizeof(uint32_t)));
}
