#include "string.cpp"
#include <assert.h>
#include <iostream>

std::ostream &operator<<(std::ostream &os, const CharQueue &q) noexcept {
  return os << "CharQueue{begin=" << (uint64_t)q.begin
            << ",end=" << (uint64_t)q.end
            << ",section_begin=" << (uint64_t)q.section_begin
            << ",section_end=" << (uint64_t)q.section_end << '}';
}

int main() {
  CharQueue q{256};
  char *val = q.enqueue(256);

  q.dequeue(256);
  char *val2 = q.enqueue(256);
  assert(val == val2);
  q.dequeue(256);

  char *val3 = q.enqueue(128);
  char *val4 = q.enqueue(128);
  q.dequeue(128);
  char *val5 = q.enqueue(127);
  assert(val3 == val5);

  std::cout << q << std::endl;
}
