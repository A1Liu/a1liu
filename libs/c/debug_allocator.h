#include <stddef.h>

#define malloc(size) __debug_alloc(size, __FILE__, __LINE__)
#define free(ptr) __debug_dealloc(ptr, __FILE__, __LINE__)
#define check(ptr) (__debug_check_alloc(ptr, __FILE__, __LINE__), ptr)

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

void *__debug_alloc(size_t, char *, unsigned int);
void __debug_dealloc(void *, char *, unsigned int);
void __debug_check_alloc(void *, char *, unsigned int);
AllocVec allocations(void);
