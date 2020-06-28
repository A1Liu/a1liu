#include "strings.h"

typedef char bool;
#define NULL ((void *)0)
#define true 1
#define false 0

String string_new(char *str) {
  String string = {str, 0};
  if (str == NULL) {
    return string;
  }

  for (; str[string.len]; string.len++)
    ;

  return string;
}

String string_from_parts(char *str, uint64_t len) {
  String string = {str, len};
  return string;
}

bool string_equals(String str1, String str2) {
  if (str1.len != str2.len) {
    return false;
  }

  if (str1.begin == str2.begin)
    return true;

  if (str1.begin == NULL || str2.begin == NULL)
    return false;

  for (uint64_t i = 0; i < str1.len; i++)
    if (str1.begin[i] != str2.begin[i])
      return false;

  return true;
}

bool string_equals_str(String str1, char *str2) {
  if (str1.begin == NULL && str2 == NULL)
    return true;

  for (uint64_t i = 0; i < str1.len; i++)
    if (str1.begin[i] != str2[i] || !str2[i])
      return false;

  return true;
}
