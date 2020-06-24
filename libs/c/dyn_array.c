#include "dyn_array.h"
#include <stdlib.h>

ElementDynArray element_array_new(void) {
  ElementDynArray arr = {NULL, 0, 0};
  return arr;
}

size_t element_array_add(ElementDynArray *arr, Element e) {
  if (arr->begin == NULL) {
    arr->begin = malloc(sizeof(*arr->begin) * 16);
    arr->cap = 16;
  } else if (arr->end == arr->cap) {
    arr->cap = arr->cap * 2;
    arr->begin = realloc(arr->begin, sizeof(*arr->begin) * arr->cap);
  }

  size_t idx = arr->end++;
  arr->begin[idx] = e;
  return idx;
}

size_t element_array_add_from(ElementDynArray *arr, Element *buf,
                              size_t count) {
  if (arr->begin == NULL || arr->cap - arr->end < count) {
    arr->cap = arr->cap / 2 + arr->cap + count;
    arr->begin = realloc(arr->begin, sizeof(*buf) * arr->cap);
  }

  size_t begin = arr->end;
  for (size_t i = 0; i < count; i++, arr->end++) {
    arr->begin[arr->end] = buf[i];
  }

  return begin;
}
