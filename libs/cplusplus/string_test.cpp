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
  TString::set_pool_size(10000);

  TString a{"hello"}, b{" bye"};
  std::cout << a + b << std::endl;

  a = b;
  assert(a == b);
  assert(a == " bye");
  assert(a != "bye");
  std::cout << a + b << std::endl;
  std::cout << "hello" + a << std::endl;
}
