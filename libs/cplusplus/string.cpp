#include "string.h"
#include <deque>
#include <mutex>

#define BLOCK_SIZE 1024 * 1024 * 4

std::mutex mut;

// Circular char queue with enqueue(uint64_t) and dequeue(uint64_t)
struct CharQueue {
  char *begin, *end;
  char *section_begin, *section_end;

  CharQueue() noexcept {
    begin = new char[BLOCK_SIZE];
    end = begin + BLOCK_SIZE;
    section_begin = section_end = begin;
  }

  ~CharQueue() noexcept { delete begin; }

  CharQueue(uint64_t len) {
    begin = new char[len];
    end = begin + len;
    section_begin = section_end = begin;
  }

  char *enqueue(uint64_t len) noexcept {
    std::lock_guard<std::mutex> g(mut);
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

  void dequeue(uint64_t len) noexcept {
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
  uint64_t ref_count;
  StringTracker() noexcept : begin(nullptr), end(nullptr), ref_count(0) {}
  StringTracker(char *begin_, char *end_) noexcept
      : begin(begin_), end(end_), ref_count(1) {}
};

uint64_t base_idx = 1;
CharQueue pool;
std::deque<StringTracker> tracker_queue;

TString::TString() noexcept : begin(nullptr), end(nullptr), tracker_index(0) {}

TString::TString(const char *s) noexcept {
  uint64_t len = strlen(s);
  if ((begin = pool.enqueue(len)) == nullptr) {
    begin = new char[len];
  }
  end = begin + len;

  for (char *i = begin; *s != '\0'; i++, s++)
    *i = *s;

  {
    std::lock_guard<std::mutex> g(mut);
    tracker_index = base_idx + tracker_queue.size();
    tracker_queue.emplace_back(begin, end);
  }
}

TString::TString(TString &&other) noexcept
    : begin(other.begin), end(other.end), tracker_index(other.tracker_index) {
  other.begin = nullptr;
  other.end = nullptr;
  other.tracker_index = 0;
}

TString::TString(const TString &other) noexcept
    : begin(other.begin), end(other.end), tracker_index(other.tracker_index) {
  std::lock_guard<std::mutex> g(mut);
  tracker_queue[other.tracker_index - base_idx].ref_count++;
}

TString::~TString() noexcept {
  if (tracker_index == -1) {
    delete begin;
  } else if (tracker_index != 0) {
    std::lock_guard<std::mutex> g(mut);
    tracker_queue[tracker_index - base_idx].ref_count--;
    for (StringTracker tracker;
         tracker_queue.size() > 0 &&
         (tracker = tracker_queue.front()).ref_count == 0;
         tracker_queue.pop_front()) {
      pool.dequeue(tracker.end - tracker.begin);
    }
  }
}

TString &TString::operator=(const TString &other) noexcept {
  begin = other.begin;
  end = other.end;
  tracker_index = other.tracker_index;

  std::lock_guard<std::mutex> g(mut);
  tracker_queue[tracker_index - base_idx].ref_count++;
  return *this;
}

TString operator+(const TString &a, const TString &b) noexcept {
  TString t;
  uint64_t len = (a.end - a.begin) + (b.end - b.begin);
  if ((t.begin = pool.enqueue(len)) == nullptr) {
    t.begin = new char[len];
  }
  t.end = t.begin + len;

  char *dest = t.begin, *src;
  for (src = a.begin; src != a.end; dest++, src++)
    *dest = *src;
  for (src = b.begin; src != b.end; dest++, src++)
    *dest = *src;

  {
    std::lock_guard<std::mutex> g(mut);
    t.tracker_index = base_idx + tracker_queue.size();
    tracker_queue.emplace_back(t.begin, t.end);
  }
  return t;
}

std::ostream &operator<<(std::ostream &os, const TString &tstring) noexcept {
  for (const char *i = tstring.begin; i != tstring.end; i++)
    os << *i;
  return os;
}
