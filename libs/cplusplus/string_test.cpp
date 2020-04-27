#include "string.cpp"
#include <iostream>
#include <string>

std::ostream &operator<<(std::ostream &os, const CharQueue &q) noexcept {
  return os << "CharQueue{begin=" << (uint64_t)q.begin
            << ",end=" << (uint64_t)q.end
            << ",section_begin=" << (uint64_t)q.section_begin
            << ",section_end=" << (uint64_t)q.section_end << '}';
}

void print_success() {
  std::cout << " \033[0;32mSUCCESS\033[0;0m" << std::endl;
}

void test_string_interning() {
  TString a{"hello"}, b{" bye"}, c{"hello"};

  std::cout << "equality overload with self" << std::flush;
  assert(a == c);
  print_success();

  std::cout << "equality overload with const char*" << std::flush;
  assert(a == "hello");
  print_success();

  std::cout << "default constructor" << std::flush;
  assert(TString() == "");
  print_success();

  std::cout << "inequality overload with const char*" << std::flush;
  assert(!(b != " bye"));
  print_success();

  std::cout << "addition overload with self" << std::flush;
  assert(a + b == "hello bye");
  print_success();

  std::cout << "assignment overload with self" << std::flush;
  c = a + b;
  assert(c == a + b);
  print_success();

  std::cout << "addition overload with const char*" << std::flush;
  assert(a + " bye" == "hello bye");
  assert("hello" + b == "hello bye");
  print_success();

  std::cout << "substr" << std::flush;
  assert(c.substr(0, 5) + " bye" == "hello bye");
  assert("hello" + c.substr(5, 4) == "hello bye");
  print_success();
}

int main() {
  TString::set_pool_size(10000);
  test_string_interning();
}
