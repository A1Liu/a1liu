#include "debug_allocator.h"
#undef malloc
#undef free
#undef check

#include <stdio.h>
#include <stdlib.h>

static AllocVec alloc_info = {NULL, 0, 0};

void *__debug_alloc(size_t size, char *file, unsigned int line) {
  fprintf(stderr, "%s:%u: allocating block of size %lu...", file, line, size);
  char *allocation = malloc(size);
  fprintf(stderr, "got 0x%lx\n", (size_t)allocation);

  if (alloc_info.begin == NULL) {
    alloc_info.begin = malloc(sizeof(AllocInfo) * 16);
    alloc_info.capacity = 16;
  }

  if (alloc_info.end == alloc_info.capacity) {
    alloc_info.capacity = alloc_info.capacity * 2;
    size_t new_size = sizeof(AllocInfo) * alloc_info.capacity;
    alloc_info.begin = realloc(alloc_info.begin, new_size);
  }

  AllocInfo *info = &alloc_info.begin[alloc_info.end++];

  info->begin = allocation;
  info->len = size;
  info->valid = true;
  info->malloc_line = line;
  info->malloc_file = file;
  info->free_file = NULL;
  info->free_line = 0;
  return allocation;
}

void __debug_dealloc(void *ptr, char *file, unsigned int line) {
  fprintf(stderr, "%s:%u: deallocating pointer at 0x%lx...", file, line,
          (size_t)ptr);

  for (size_t i = alloc_info.end - 1; i != -1; i--) {
    AllocInfo *info = &alloc_info.begin[i];
    if (ptr < info->begin || ptr - info->begin >= info->len)
      continue;

    if (!info->valid) {
      fprintf(stderr, "FAILED (malloc at %s:%u, free at %s:%u)\n",
              info->malloc_file, info->malloc_line, info->free_file,
              info->free_line);
      exit(1);
    }

    if (ptr != info->begin) {
      fprintf(stderr,
              "FAILED (malloc at %s:%u, free called on "
              "0x%lx, should've been called on 0x%lx)\n",
              info->malloc_file, info->malloc_line, (size_t)ptr,
              (size_t)info->begin);
      exit(1);
    }

    fprintf(stderr, "SUCCESS\n");
    info->valid = false;
    info->free_file = file;
    info->free_line = line;
    free(ptr);
    return;
  }

  fprintf(stderr, "FAILED (couldn't find pointer)\n");
  exit(1);
}

void __debug_check_alloc(void *ptr, char *file, unsigned int line) {
  fprintf(stderr, "%s:%u: checking pointer at 0x%lx...", file, line,
          (size_t)ptr);

  for (size_t i = alloc_info.end - 1; i != -1; i--) {
    AllocInfo *info = &alloc_info.begin[i];
    if (ptr < info->begin || ptr - info->begin >= info->len)
      continue;

    if (!info->valid) {
      fprintf(stderr, "FAILED (malloc at %s:%u, freed at %s:%u)\n",
              info->malloc_file, info->malloc_line, info->free_file,
              info->free_line);
      exit(1);
    }

    fprintf(stderr, "SUCCESS\n");
    return;
  }

  fprintf(stderr, "FAILED (couldn't find pointer)\n");
  exit(1);
}
