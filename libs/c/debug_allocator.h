#include <stddef.h>

#define malloc(size) __debug_alloc(size, __FILE__, __LINE__)
#define realloc(ptr, size) __debug_realloc(ptr, size, __FILE__, __LINE__)
#define free(ptr) __debug_dealloc(ptr, __FILE__, __LINE__)
#define check(ptr) (__debug_check_alloc(ptr, __FILE__, __LINE__), ptr)

void *__debug_alloc(size_t, char *, unsigned int);
void *__debug_realloc(void *, size_t, char *, unsigned int);
void __debug_dealloc(void *, char *, unsigned int);
void __debug_check_alloc(void *, char *, unsigned int);
