#include "string.h"
#include <cstring>
#include <deque>
#include <iostream>
#include <mutex>

// Circular char queue with enqueue(uint64_t) and dequeue(uint64_t)
struct CharQueue {
  char *begin, *end;
  char *section_begin, *section_end;

  CharQueue() noexcept
      : begin(nullptr), end(nullptr), section_begin(nullptr),
        section_end(nullptr) {}

  ~CharQueue() noexcept {
    if (begin)
      delete begin;
  }

  CharQueue(uint64_t len) {
    begin = new char[len];
    end = begin + len;
    section_begin = section_end = begin;
  }

  uint64_t size() {
    if (!begin)
      return 0;

    if (section_begin <= section_end) {
      return section_end - section_begin;
    } else {
      return (end - section_begin) + (section_end - begin);
    }
  }

  char *enqueue(uint64_t len) noexcept {
    if (!begin)
      return nullptr;
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
std::mutex mut;
CharQueue pool;
std::deque<StringTracker> tracker_queue;

static void alloc_string(TString *tstring, uint64_t len) {
  mut.lock();
  tstring->begin = pool.enqueue(len);
  mut.unlock();

  if (tstring->begin == nullptr) {
    tstring->begin = new char[len];
    tstring->end = tstring->begin + len;
    tstring->tracker_index = -1;
  } else {
    tstring->end = tstring->begin + len;
    std::lock_guard<std::mutex> g(mut);
    tstring->tracker_index = base_idx + tracker_queue.size();
    tracker_queue.emplace_back(tstring->begin, tstring->end);
  }
}

void TString::set_pool_size(uint64_t size) noexcept {
  std::lock_guard<std::mutex> g(mut);
  new (&pool) CharQueue(size);
}

TString::TString() noexcept : begin(nullptr), end(nullptr), tracker_index(0) {}

TString::TString(const char *s) noexcept {
  uint64_t len = strlen(s);
  alloc_string(this, len);

  for (char *i = begin; *s != '\0'; i++, s++)
    *i = *s;
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
      base_idx++;
    }
  }
}

TString &TString::operator=(const TString &other) noexcept {
  this->~TString();
  if (other.tracker_index == -1) {
    alloc_string(this, other.size());
    char *dest = begin, *src = other.begin;
    for (; dest != end; src++, dest++)
      *dest = *src;

    return *this;
  }

  begin = other.begin;
  end = other.end;
  tracker_index = other.tracker_index;
  if (tracker_index == 0) {
    return *this;
  }

  std::lock_guard<std::mutex> g(mut);
  tracker_queue[tracker_index - base_idx].ref_count++;
  return *this;
}

uint64_t TString::size() const noexcept { return end - begin; }

TString TString::substr(uint64_t idx, uint64_t len) const noexcept {
  TString t;
  t = *this;
  t.begin += idx;
  t.end += idx + len;
  return t;
}

char &TString::front() noexcept { return *begin; }
const char &TString::front() const noexcept { return *begin; }
char &TString::back() noexcept { return *(end - 1); }
const char &TString::back() const noexcept { return *(end - 1); }

bool operator==(const TString &a, const TString &b) noexcept {
  if (a.begin == b.begin && a.end == b.end) {
    return true;
  }

  if (a.size() != b.size())
    return false;

  const char *ac = a.begin, *bc = b.begin;
  for (; ac != a.end && *ac == *bc; ac++, bc++)
    ;
  return ac == a.end;
}

bool operator==(const TString &a, const char *bc) noexcept {
  if (bc == nullptr)
    return false;
  const char *ac = a.begin;
  for (; ac != a.end && *bc != '\0' && *ac == *bc; ac++, bc++)
    ;

  return ac == a.end && *bc == '\0';
}

bool operator==(const char *a, const TString &b) noexcept { return b == a; }

bool operator!=(const TString &a, const TString &b) noexcept {
  return !(a == b);
}
bool operator!=(const TString &a, const char *b) noexcept { return !(a == b); }
bool operator!=(const char *a, const TString &b) noexcept { return !(a == b); }

TString operator+(const TString &a, const TString &b) noexcept {
  TString t;
  uint64_t len = a.size() + b.size();
  alloc_string(&t, len);

  char *dest = t.begin, *src;
  for (src = a.begin; src != a.end; dest++, src++)
    *dest = *src;
  for (src = b.begin; src != b.end; dest++, src++)
    *dest = *src;

  return t;
}

TString operator+(const TString &a, const char *bc) noexcept {
  TString t;
  if (bc == nullptr) {
    t = a;
    return t;
  }

  alloc_string(&t, a.size() + strlen(bc));

  char *dest = t.begin;
  const char *src;
  for (src = a.begin; src != a.end; dest++, src++)
    *dest = *src;
  for (src = bc; *src != '\0'; dest++, src++)
    *dest = *src;

  return t;
}

TString operator+(const char *ac, const TString &b) noexcept {
  TString t;
  if (ac == nullptr) {
    t = b;
    return t;
  }

  alloc_string(&t, b.size() + strlen(ac));

  char *dest = t.begin;
  const char *src;
  for (src = ac; *src != '\0'; dest++, src++)
    *dest = *src;
  for (src = b.begin; src != b.end; dest++, src++)
    *dest = *src;

  return t;
}

std::ostream &operator<<(std::ostream &os, const TString &tstring) noexcept {
  for (const char *i = tstring.begin; i != tstring.end; i++)
    os << *i;
  return os;
}
