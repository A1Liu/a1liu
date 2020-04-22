#pragma once
#include <cstdint>
#include <ostream>

struct TString {
  char *begin = nullptr, *end = nullptr;
  uint64_t tracker_index = 0;

  TString() noexcept;
  TString(const char *) noexcept;
  TString(TString &&other) noexcept;
  TString(const TString &other) noexcept;
  ~TString() noexcept;

  TString &operator=(const TString &) noexcept;
};

TString operator+(const TString &, const TString &) noexcept;
std::ostream &operator<<(std::ostream &, const TString &) noexcept;
