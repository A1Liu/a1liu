#include <stdint.h>

typedef struct {
  char *begin;
  uint64_t len;
} String;

typedef char bool;

String string_new(char *);

String string_from_parts(char *, uint64_t);

bool string_equals(String, String);

bool string_equals_str(String, char *);
