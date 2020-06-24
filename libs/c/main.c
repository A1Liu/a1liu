#include <stdio.h>
#include <sys/stat.h>

#include "debug_allocator.h"

typedef struct {
  char *path;
  struct stat stats;
} File;

typedef struct {
  File *begin;
  unsigned long int end;
  unsigned long int capacity;
} Vector;

File file_new(char *path) {
  File file;
  if (stat(path, &file.stats) == -1) {
    file.path = NULL;
  } else
    file.path = path;
  return file;
}

Vector vector_new(void) {
  Vector vec = {NULL, 0, 0};
  return vec;
}

void vector_add(Vector *vec, File file) {
  if (vec->begin == NULL) {
    vec->begin = malloc(sizeof(AllocInfo) * 16);
    vec->capacity = 16;
  }

  if (vec->end == vec->capacity) {
    vec->capacity = vec->capacity * 2;
    size_t new_size = sizeof(AllocInfo) * vec->capacity;
    vec->begin = realloc(vec->begin, new_size);
  }

  vec->begin[vec->end++] = file;
}

int main(int argc, char **argv) {
  Vector vec = vector_new();
  for (int i = 0; i < argc; i++) {
    File f = file_new(argv[i]);
    if (f.path != NULL)
      vector_add(&vec, f);
  }

  for (unsigned int i = vec.end - 1; i >= 0; i--) {
    printf("%s\n", check(&vec.begin[i])->path);
  }

  free(vec.begin);

  return 0;
}
