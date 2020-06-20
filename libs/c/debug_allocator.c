#include <stddef.h>
#include <stdio.h>

#define malloc(size) alloc(size, __FILE__, __LINE__)
#define free(ptr) dealloc(ptr, __FILE__, __LINE__)

typedef char bool;
#define false 0
#define true 1

void *alloc(size_t, char *, size_t);
bool dealloc(void *, char *, size_t);

int main() {
  void *hello = malloc(16);
  free(hello);
}

void *alloc(size_t size, char *file, size_t line) {
  fprintf(stderr, "%s:%li: allocating block of size %li\n", file, line, size);
  return NULL;
}
bool dealloc(void *ptr, char *file, size_t line) {
  fprintf(stderr, "%s:%li: deallocating pointer at address %lx\n", file, line,
          (size_t)ptr);
  return false;
}
