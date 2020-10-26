#ifndef QUEUE
#define QUEUE
#include <cstdint>

template <typename Data> struct Queue {
  char *data;
  uint64_t data_length;
  uint32_t data;
};

#endif
