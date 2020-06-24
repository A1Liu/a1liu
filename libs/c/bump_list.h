#include <stddef.h>

typedef struct {
  void *next;
  char *bump;
  size_t len;
} BumpList;

void *bump_alloc(BumpList *, size_t);
BumpList *bump_new(void);
