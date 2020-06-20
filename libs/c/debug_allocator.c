#include "debug_allocator.h"
#undef malloc
#undef free
#include <stdio.h>
#include <stdlib.h>

static AllocVec alloc_info = {NULL, 0, 0};

void *alloc(size_t size, char *file, unsigned int line) {
  fprintf(stderr, "%s:%u: allocating block of size %lu\n", file, line, size);
  char *allocation = malloc(size);

  if (alloc_info.begin == NULL) {
    alloc_info.begin = malloc(sizeof(AllocInfo) * 16);
    alloc_info.capacity = 16;
  }

  if (alloc_info.end == alloc_info.capacity) {
    alloc_info.capacity = alloc_info.capacity * 2;
    size_t new_size = sizeof(AllocInfo) * alloc_info.capacity;
    alloc_info.begin = realloc(alloc_info.begin, new_size);
  }

  AllocInfo *info = &alloc_info.begin[alloc_info.end];
  alloc_info.end++;

  info->begin = allocation;
  info->len = size;
  info->valid = true;
  info->line_number = line;
  info->file = file;
  return allocation;
}

void dealloc(void *ptr, char *file, unsigned int line) {
  fprintf(stderr, "%s:%u: deallocating pointer at address 0x%lx...", file, line,
          (size_t)ptr);

  for (size_t i = alloc_info.end - 1; i >= 0; i--) {
    AllocInfo *info = &alloc_info.begin[i];
    if (ptr < info->begin || ptr - info->begin >= info->len)
      continue;

    if (!info->valid) {
      fprintf(stderr,
              "FAILED (alloc came from %s:%u, memory was already freed)\n",
              info->file, info->line_number);
      exit(1);
    }

    if (ptr != info->begin) {
      fprintf(stderr,
              "FAILED (alloc came from %s:%u, dealloc was called on "
              "0x%lx when it should've been called on 0x%lx)\n",
              info->file, info->line_number, (size_t)ptr, (size_t)info->begin);
      exit(1);
    }

    fprintf(stderr, "SUCCESS\n");
    info->valid = false;
    free(ptr);
    return;
  }

  fprintf(stderr, "FAILED (couldn't find pointer)\n");
  exit(1);
}
