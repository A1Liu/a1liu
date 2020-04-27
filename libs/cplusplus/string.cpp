#include "string.h"
#include <assert.h>
#include <cstring>
#include <deque>
#include <iostream>
#include <mutex>

#define INTERN_LENGTH 23

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

  char *eat_up_end() {
    if (section_begin <= section_end && section_end != end) {
      char *ret_val = section_end;
      section_end = section_begin == begin ? end : begin;
      return ret_val;
    }
    return nullptr;
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

typedef union {
  uint64_t val;
  struct {
    uint8_t a, b, c, d, e, f, g, h;
  };
} ConvertEndian;

struct StringTracker {
  char *start, *end;
  uint64_t ref_count;
  StringTracker() noexcept : start(nullptr), end(nullptr), ref_count(0) {}
  StringTracker(char *start_, char *end_) noexcept
      : start(start_), end(end_), ref_count(1) {}
  StringTracker(char *start_, char *end_, uint64_t ref_count_) noexcept
      : start(start_), end(end_), ref_count(ref_count_) {}
};

uint64_t base_idx = 1;
std::mutex mut;
CharQueue pool;
std::deque<StringTracker> tracker_queue;

static uint64_t to_from_be(uint64_t val) {
  if (ConvertEndian{0x01}.h == 1) {
    return val;
  } else {
    ConvertEndian source, dest;
    source.val = val;
    dest.a = source.h, dest.b = source.g, dest.c = source.f, dest.d = source.e,
    dest.e = source.d, dest.f = source.c, dest.g = source.b, dest.h = source.a;
    return dest.val;
  }
}

static void alloc_string(TString *tstring, uint64_t len) {
  mut.lock();
  tstring->start = pool.enqueue(len);
  mut.unlock();

  if (tstring->start != nullptr) {
    std::lock_guard<std::mutex> g(mut);
    tstring->tracker_index = base_idx + tracker_queue.size();
    tracker_queue.emplace_back(tstring->start, tstring->start + len);
    return;
  }

  mut.lock();
  char *last_start = pool.eat_up_end();
  if (last_start != nullptr) {
    tracker_queue.emplace_back(last_start, pool.end, 0);
  }
  tstring->start = pool.enqueue(len);
  mut.unlock();

  if (tstring->start == nullptr) {
    tstring->start = new char[len];
    tstring->tracker_index = -1;
  } else {
    std::lock_guard<std::mutex> g(mut);
    tstring->tracker_index = base_idx + tracker_queue.size();
    tracker_queue.emplace_back(tstring->start, tstring->start + len);
    return;
  }
}

void TString::set_pool_size(uint64_t size) noexcept {
  std::lock_guard<std::mutex> g(mut);
  new (&pool) CharQueue(size);
}

TString::TString() noexcept : start(nullptr), len_value(0), tracker_index(0) {}

TString::TString(const char *s) noexcept {
  if (s == nullptr) {
    len_value = tracker_index = 0;
    start = nullptr;
    return;
  }

  uint64_t len = strlen(s);
  if (len == 0) {
    return;
  }

  if (len <= INTERN_LENGTH) {
    len_bytes[7] = len;
    for (char *i = (char *)this; *s != '\0'; i++, s++)
      *i = *s;
  } else {
    len_value = to_from_be(len << 8);
    alloc_string(this, len);
    for (char *i = start; *s != '\0'; i++, s++)
      *i = *s;
  }
}

TString::TString(TString &&other) noexcept
    : start(other.start), len_value(other.len_value),
      tracker_index(other.tracker_index) {
  other.tracker_index = 0;
  other.start = nullptr;
  other.len_value = 0;
}

TString::TString(const TString &other) noexcept
    : start(other.start), len_value(other.len_value),
      tracker_index(other.tracker_index) {
  if (other.len_bytes[7] > INTERN_LENGTH) {
    std::lock_guard<std::mutex> g(mut);
    tracker_queue[other.tracker_index - base_idx].ref_count++;
  }
}

TString::~TString() noexcept {
  if (len_value == 0 || len_bytes[7] != 0) {
    return;
  }

  if (tracker_index == -1) {
    delete start;
  } else if (tracker_index != 0) {
    std::lock_guard<std::mutex> g(mut);
    tracker_queue[tracker_index - base_idx].ref_count--;
    for (StringTracker tracker;
         tracker_queue.size() > 0 &&
         (tracker = tracker_queue.front()).ref_count == 0;
         tracker_queue.pop_front()) {
      pool.dequeue(tracker.end - tracker.start);
      base_idx++;
    }
  }
}

TString &TString::operator=(const TString &other) noexcept {
  this->~TString();

  if (other.len_bytes[7] == 0 && other.tracker_index == -1) {
    alloc_string(this, other.size());
    uint64_t len = to_from_be(len_value) >> 8;
    for (uint64_t i = 0; i < len; i++)
      *(this->start + i) = *(other.start + i);

    return *this;
  }

  start = other.start;
  len_value = other.len_value;
  tracker_index = other.tracker_index;
  if (other.len_bytes[7] != 0 || tracker_index == 0)
    return *this;

  std::lock_guard<std::mutex> g(mut);
  tracker_queue[tracker_index - base_idx].ref_count++;
  return *this;
}

const char *TString::begin() const noexcept {
  if (len_bytes[7] != 0)
    return (char *)this;
  return start;
}

const char *TString::end() const noexcept {
  if (len_bytes[7] != 0)
    return ((char *)this) + len_bytes[7];
  return start + (to_from_be(len_value) >> 8);
}

uint64_t TString::size() const noexcept {
  return len_bytes[7] != 0 ? len_bytes[7] : (to_from_be(len_value) >> 8);
}

// TString TString::substr(uint64_t idx, uint64_t len) const noexcept {
//   if (len == 0)
//     return TString();
//
//   assert(idx < size());
//   assert(idx + len <= size());
//
//   if (len <= INTERN_LENGTH) {
//   }
//
//   TString t;
//   t = *this;
//   t.start += idx;
//   set_tstring_len(&t, len);
//   return t;
// }

bool operator==(const TString &a, const TString &b) noexcept {
  if (a.len_bytes[7] != b.len_bytes[7])
    return false;

  if (a.len_bytes[7] != 0) {
    uint8_t len = 0;
    for (char *ac = (char *)&a, *bc = (char *)&b;
         len < a.len_bytes[7] && *ac == *bc; ac++, bc++, len++)
      ;

    return len == a.len_bytes[7];
  }

  if (a.start == b.start)
    return a.len_value == b.len_value;

  uint64_t len = 0;
  for (char *ac = (char *)&a, *bc = (char *)&b; len < a.size() && *ac == *bc;
       ac++, bc++, len++)
    ;
  return len == a.size();
}

bool operator==(const TString &a,
                const char *bc) noexcept { // TODO fix this for the case that
                                           // tstring contains null char
  if (a.len_bytes[7] != 0) {
    return strncmp((char *)&a, bc, a.len_bytes[7]) == 0;
  }

  return strncmp(a.start, bc, to_from_be(a.len_value) >> 8) == 0;
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
  if (len == 0) {
    return t;
  }

  if (len <= INTERN_LENGTH) {
    t.len_bytes[7] = len;
    char *tc = (char *)&t;
    for (const char *ac = a.begin(); ac != a.end(); tc++, ac++)
      *tc = *ac;
    for (const char *bc = b.begin(); bc != b.end(); tc++, bc++)
      *tc = *bc;
  } else {
    t.len_value = to_from_be(len << 8);
    alloc_string(&t, len);
    char *tc = (char *)&t;
    for (const char *ac = a.begin(); ac != a.end(); tc++, ac++)
      *tc = *ac;
    for (const char *bc = b.begin(); bc != b.end(); tc++, bc++)
      *tc = *bc;
  }
  return t;
}

TString operator+(const TString &a, const char *bc) noexcept {
  TString t;

  uint64_t bc_size = strlen(bc);
  uint64_t len = a.size() + bc_size;

  char *tc;
  if (len <= INTERN_LENGTH) {
    t.len_bytes[7] = len;
    tc = (char *)&t;
  } else {
    t.len_value = to_from_be(len << 8);
    alloc_string(&t, a.size() + bc_size);
    tc = t.start;
  }

  for (const char *ac = a.begin(); ac != a.end(); tc++, ac++)
    *tc = *ac;
  for (; *bc != '\0'; tc++, bc++)
    *tc = *bc;
  return t;
}

TString operator+(const char *ac, const TString &b) noexcept {
  TString t;

  uint64_t ac_size = strlen(ac);
  uint64_t len = ac_size + b.size();

  char *tc;
  if (len <= INTERN_LENGTH) {
    t.len_bytes[7] = len;
    tc = (char *)&t;
  } else {
    t.len_value = to_from_be(len << 8);
    alloc_string(&t, len);
    tc = t.start;
  }

  for (; *ac != '\0'; tc++, ac++)
    *tc = *ac;
  for (const char *bc = b.begin(); bc != b.end(); tc++, bc++)
    *tc = *bc;
  return t;
}

std::ostream &operator<<(std::ostream &os, const TString &tstring) noexcept {
  for (const char *tc = tstring.begin(); tc != tstring.end(); tc++) {
    os << *tc;
  }
  return os;
}
