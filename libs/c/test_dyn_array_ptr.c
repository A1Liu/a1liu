#include "dyn_array_ptr.c"
#include <stdio.h>

typedef struct {
  uint64_t hello;
} Hello;

int main() {
  dyn_array_declare(hello, uint64_t);
  dyn_array_declare(hello2, uint32_t);

  dyn_array_add(&hello, 12);
  dyn_array_add_from(&hello2, hello, 1);
  printf("%llu\n", hello[0]);
  printf("%llu\n", dyn_array_capacity(hello));
  printf("%llu\n", dyn_array_len(hello));
}
