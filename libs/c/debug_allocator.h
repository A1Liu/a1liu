#include <stddef.h>

#define malloc(size) alloc(size, __FILE__, __LINE__)
#define free(ptr) dealloc(ptr, __FILE__, __LINE__)

typedef char bool;
#define false 0
#define true 1

typedef struct {
  void *begin;
  size_t len;
  unsigned int line_number;
  bool valid;
  char *file;
} AllocInfo;

typedef struct {
  AllocInfo *begin;
  size_t end;
  size_t capacity;
} AllocVec;

void *alloc(size_t, char *, unsigned int);
void dealloc(void *, char *, unsigned int);
AllocVec allocations(void);

int main() {
  void *hello = malloc(16);
  free(hello);
}
