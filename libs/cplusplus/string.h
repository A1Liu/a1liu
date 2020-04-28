#pragma once
#include <cstdint>
#include <ostream>

struct TString {
  uint64_t tracker_index = 0;
  char *start = nullptr;
  union {
    uint64_t len_value = 0;
    uint8_t len_bytes[8];
  };

  static void set_pool_size(uint64_t size) noexcept;

  TString() noexcept;
  TString(const char *) noexcept;
  TString(TString &&other) noexcept;
  TString(const TString &other) noexcept;
  ~TString() noexcept;

  TString &operator=(const TString &) noexcept;

  const char *begin() const noexcept;
  char *begin() noexcept;
  const char *end() const noexcept;
  char *end() noexcept;

  const char &operator[](uint64_t idx) const noexcept;
  char &operator[](uint64_t idx) noexcept;

  const char &at(uint64_t idx) const noexcept;
  char &at(uint64_t idx) noexcept;

  uint64_t size() const noexcept;
  TString substr(uint64_t idx, uint64_t len) const noexcept;
};

bool operator==(const TString &, const TString &) noexcept;
bool operator==(const TString &a, const char *b) noexcept;
bool operator==(const char *, const TString &) noexcept;

bool operator!=(const TString &, const TString &) noexcept;
bool operator!=(const TString &, const char *) noexcept;
bool operator!=(const char *, const TString &) noexcept;

TString operator+(const TString &, const TString &) noexcept;
TString operator+(const char *, const TString &) noexcept;
TString operator+(const TString &, const char *) noexcept;

std::ostream &operator<<(std::ostream &, const TString &) noexcept;
