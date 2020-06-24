#include <stddef.h>

typedef struct {
  char *field_1;
  char *field_2;
  char *field_3;
  char *field_4;
} Element;

typedef struct {
  Element *begin;
  size_t end;
  size_t cap;
} ElementDynArray;

ElementDynArray element_array_new(void);
size_t element_array_add(ElementDynArray *, Element);
size_t element_array_add_from(ElementDynArray *, Element *, size_t);
