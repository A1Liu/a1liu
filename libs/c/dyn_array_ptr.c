#include "dyn_array_ptr.h"
#include <stdlib.h>

uint64_t *__dyn_array_capacity_ptr(void *arr) {
  char *capa_loc = ((char *)arr) - sizeof(uint64_t) * 2;
  return (uint64_t *)capa_loc;
}
uint64_t *__dyn_array_len_ptr(void *arr) {
  char *len_loc = ((char *)arr) - sizeof(uint64_t);
  return (uint64_t *)len_loc;
}

void __dyn_array_ensure_add(void *arr_, size_t size) {
  void **arr = (void **)arr_;
  void *buffer = *arr;

  if (buffer == NULL) {
    buffer = *arr = malloc(size * 16);
    *__dyn_array_capacity_ptr(buffer) = 16;
    *__dyn_array_len_ptr(buffer) = 0;
    return;
  }

  uint64_t *buffer_begin = __dyn_array_capacity_ptr(buffer);
  uint64_t len = *__dyn_array_len_ptr(buffer);
  uint64_t capacity = *buffer_begin;
  if (len < capacity)
    return;

  capacity = capacity / 2 + capacity;
  buffer_begin = realloc(buffer_begin, size * capacity);
  *buffer_begin = capacity;
  *arr = buffer_begin + 2;
}

void __dyn_array_add_from(void *arr_, size_t size, void *from, size_t len) {
  void **arr = (void **)arr_;
  void *buffer = *arr;

  if (buffer == NULL) {
    buffer = *arr = malloc(size * (16 + len));
    *__dyn_array_capacity_ptr(buffer) = 16 + len;
    *__dyn_array_len_ptr(buffer) = 0;
    return;
  }

  uint64_t *buffer_begin = __dyn_array_capacity_ptr(buffer);
  uint64_t array_len = *__dyn_array_len_ptr(buffer);
  uint64_t capacity = *buffer_begin;
  if (array_len + len < capacity)
    return;

  capacity = capacity / 2 + capacity + len;
  buffer_begin = realloc(buffer_begin, size * capacity);
  *buffer_begin = capacity;
  *arr = buffer_begin + 2;
}
