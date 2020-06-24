#include "bump_list.h"
#include <stdlib.h>

// if ptr != NULL, then ptr is the aligned bump pointer value to return, and
// next_bump is the next value of the bump pointer
typedef struct {
  void *ptr;
  void *next_bump;
} Bump;

// align must be a power of 2
Bump bump_ptr(void *bump_, void *end, size_t size) {
  char *bump = (char *)(((((size_t)bump_ - 1) >> 3) + 1) << 3);
  Bump result = {NULL, NULL};
  result.next_bump = bump + size;
  if (result.next_bump > end) {
    result.next_bump = NULL;
  } else
    result.ptr = bump;

  return result;
}

void *bump_alloc(BumpList *list, size_t size) {
  char *array_begin = (char *)(list + 1), *bucket_end = array_begin + list->len;

  Bump result = bump_ptr(list->bump, bucket_end, size);
  if (result.ptr != NULL) {
    list->bump = result.next_bump;
    return result.ptr;
  }

  if (list->next != NULL)
    return bump_alloc(list->next, size);

  size_t next_len = list->len / 2 + list->len;
  if (next_len < size)
    next_len = size;

  list->next = malloc(sizeof(*list) + next_len);

  BumpList *next = list->next;
  next->len = next_len;
  next->next = NULL;
  char *ptr = (char *)(next + 1);
  next->bump = ptr + size;

  return ptr;
}

BumpList *bump_new(void) {
  BumpList *list = malloc(sizeof(BumpList) + 1024);
  list->next = NULL;
  list->bump = (char *)(list + 1);
  list->len = 1024;
  return list;
}
