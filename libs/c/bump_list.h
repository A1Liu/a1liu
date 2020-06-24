#include <stddef.h>

typedef struct {
  void *next;
  char *bump;
  size_t len;
} BumpList;

void *bump_alloc(BumpList *list, size_t size);
BumpList *bump_new(void);
