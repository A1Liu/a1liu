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
  uint64_t size() const noexcept;
  static void set_pool_size(uint64_t size) noexcept;
};

inline bool operator==(const TString &, const TString &) noexcept;
inline bool operator==(const TString &a, const char *b) noexcept;
inline bool operator==(const char *, const TString &) noexcept;

inline bool operator!=(const TString &, const TString &) noexcept;
inline bool operator!=(const TString &, const char *) noexcept;
inline bool operator!=(const char *, const TString &) noexcept;

inline TString operator+(const TString &, const TString &) noexcept;
inline TString operator+(const char *, const TString &) noexcept;
inline TString operator+(const TString &, const char *) noexcept;

std::ostream &operator<<(std::ostream &, const TString &) noexcept;
