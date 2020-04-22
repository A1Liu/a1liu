#pragma once
#include <cstdint>
#include <ostream>

struct TString {
  const char *begin = nullptr, *end = nullptr;
  int64_t tracker_index = 0;

  TString(const char *) noexcept;
  TString(TString &&other) noexcept;
  TString(const TString &other) noexcept;
  ~TString() noexcept;
};
std::ostream &operator<<(std::ostream &, const TString &) noexcept;
