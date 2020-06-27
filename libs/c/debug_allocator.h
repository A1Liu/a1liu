#include <stddef.h>

#define DEBUG_UNINIT 0xbadfaded
#define DEBUG_FREED 0xdeadbeef
#define DEBUG_NEARBY_FREED 0xdeaddead
#define DEBUG_NEARBY_ALLOCATED 0xdeafdeaf

#define malloc(size) __debug_alloc(size, __FILE__, __LINE__)
#define realloc(ptr, size) __debug_realloc(ptr, size, __FILE__, __LINE__)
#define free(ptr) __debug_dealloc(ptr, __FILE__, __LINE__)
#define check(ptr) (__debug_check_alloc(ptr, __FILE__, __LINE__), ptr)

// Replacement for malloc that tracks the file & line where it was called
void *__debug_alloc(size_t, char *, unsigned int);

// Replacement for realloc that tracks the file & line where it was called
void *__debug_realloc(void *, size_t, char *, unsigned int);

// Replacement for free that tracks the file & line where it was called
void __debug_dealloc(void *, char *, unsigned int);

// Checks the given pointer to see if it has been allocated already or not
void __debug_check_alloc(void *, char *, unsigned int);
