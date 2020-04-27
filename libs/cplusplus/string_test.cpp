#include "string.cpp"
#include <iostream>
#include <string>

std::ostream &operator<<(std::ostream &os, const CharQueue &q) noexcept {
  return os << "CharQueue{begin=" << (uint64_t)q.begin
            << ",end=" << (uint64_t)q.end
            << ",section_begin=" << (uint64_t)q.section_begin
            << ",section_end=" << (uint64_t)q.section_end << '}';
}

void test_string_interning() {
  TString a{"hello"}, b{" bye"}, c{"hello"};

  std::cout << "equality overload with self" << std::flush;
  assert(a == c);
  std::cout << " SUCCESS" << std::endl;

  std::cout << "equality overload with const char*" << std::flush;
  assert(a == "hello");
  std::cout << " SUCCESS" << std::endl;

  std::cout << "inequality overload with const char*" << std::flush;
  assert(!(b != " bye"));
  std::cout << " SUCCESS" << std::endl;

  std::cout << "addition overload with self" << std::flush;
  assert(a + b == "hello bye");
  std::cout << " SUCCESS" << std::endl;

  std::cout << "addition overload with const char*" << std::flush;
  assert(a + " bye" == "hello bye");
  assert("hello" + b == "hello bye");
  std::cout << " SUCCESS" << std::endl;
}

int main() {
  TString::set_pool_size(10000);
  test_string_interning();
}
