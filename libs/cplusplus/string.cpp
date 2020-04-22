#include "string.h"
#include <deque>
#include <vector>

#define BLOCK_SIZE 1024 * 1024

// Circular char queue with enqueue(uint64_t) and dequeue(uint64_t)
struct CharQueue {
  char *begin, *end;
  char *section_begin, *section_end;

  CharQueue() {
    begin = new char[BLOCK_SIZE];
    end = begin + BLOCK_SIZE;
    section_begin = section_end = begin;
  }

  CharQueue(uint64_t len) {
    begin = new char[len];
    end = begin + len;
    section_begin = section_end = begin;
  }

  char *enqueue(uint64_t len) {
    if (section_begin <= section_end) {
      if (end - section_end >= len) {
        char *ret_val = section_end;
        section_end += len;
        return ret_val;
      }

      if (section_begin - begin > len) {
        section_end = begin + len;
        return begin;
      }

      return nullptr;
    }

    if (section_begin - section_end > len) {
      char *ret_val = section_end;
      section_end += len;
      return ret_val;
    }

    return nullptr;
  }

  void dequeue(uint64_t len) {
    if (section_begin <= section_end) {
      section_begin += len;
      if (section_begin == section_end) {
        section_begin = section_end = begin;
      }
      return;
    }

    uint64_t end_len = end - section_begin;
    if (end_len > len) {
      section_begin += len;
      if (section_begin == section_end) {
        section_begin = section_end = begin;
      }
      return;
    }

    len -= end_len;
    section_begin = begin + len;
    if (section_begin == section_end) {
      section_begin = section_end = begin;
    }
  }
};

struct StringTracker {
  char *begin, *end;
  uint64_t ref_count = 1;
};

uint64_t base_idx = 1;
std::deque<StringTracker> tracker_queue;
std::vector<StringBlock> blocks;

TString::TString(const char *s) noexcept {
  begin = s;
  end = begin + strlen(s);
  tracker_index = 0;
}

TString::TString(TString &&other) noexcept
    : begin(other.begin), end(other.end), tracker_index(other.tracker_index) {
  other.begin = nullptr;
  other.end = nullptr;
  other.tracker_index = 0;
}

TString::TString(const TString &other) noexcept
    : begin(other.begin), end(other.end), tracker_index(other.tracker_index) {
  tracker_queue[other.tracker_index - base_idx].ref_count++;
}

TString::~TString() noexcept {
  if (tracker_index > 0) {
    tracker_queue[tracker_index - base_idx].ref_count--;
  } else if (tracker_index < 0) {
  }
}

std::ostream &operator<<(std::ostream &os, const TString &tstring) noexcept {
  for (const char *i = tstring.begin; i != tstring.end; i++) {
    os << *i;
  }
  return os;
}
