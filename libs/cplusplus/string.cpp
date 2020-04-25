#include "string.h"
#include <assert.h>
#include <cstring>
#include <deque>
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
  char *begin, *end;
  uint64_t ref_count;
  StringTracker() noexcept : begin(nullptr), end(nullptr), ref_count(0) {}
  StringTracker(char *begin_, char *end_) noexcept
      : begin(begin_), end(end_), ref_count(1) {}
  StringTracker(char *begin_, char *end_, uint64_t ref_count_) noexcept
      : begin(begin_), end(end_), ref_count(ref_count_) {}
};

uint64_t base_idx = 1;
std::mutex mut;
CharQueue pool;
std::deque<StringTracker> tracker_queue;

inline bool is_big_endian() {
  ConvertEndian convert = {0x01};
  return convert.h == 1;
}

uint64_t be_rshift_8(uint64_t val) {
  ConvertEndian convert = {val};
  convert.h = convert.g, convert.g = convert.f, convert.f = convert.e,
  convert.e = convert.d, convert.d = convert.c, convert.c = convert.b,
  convert.b = convert.a, convert.a = 0;
  return convert.val;
}

uint64_t to_from_be(uint64_t val) {
  if (is_big_endian()) {
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
  tstring->len = len;

  mut.lock();
  tstring->begin = pool.enqueue(len);
  mut.unlock();

  if (tstring->begin != nullptr) {
    tstring->len = len;
    std::lock_guard<std::mutex> g(mut);
    tstring->tracker_index = base_idx + tracker_queue.size();
    tracker_queue.emplace_back(tstring->begin, tstring->begin + len);
    return;
  }

  mut.lock();
  char *last_begin = pool.eat_up_end();
  if (last_begin != nullptr) {
    tracker_queue.emplace_back(last_begin, pool.end, 0);
  }
  tstring->begin = pool.enqueue(len);
  mut.unlock();

  if (tstring->begin == nullptr) {
    tstring->begin = new char[len];
    tstring->tracker_index = -1;
  } else {
    std::lock_guard<std::mutex> g(mut);
    tstring->tracker_index = base_idx + tracker_queue.size();
    tracker_queue.emplace_back(tstring->begin, tstring->begin + len);
    return;
  }
}

void TString::set_pool_size(uint64_t size) noexcept {
  std::lock_guard<std::mutex> g(mut);
  new (&pool) CharQueue(size);
}

TString::TString() noexcept : begin(nullptr), len(0), tracker_index(0) {}

TString::TString(const char *s) noexcept {
  uint64_t len = strlen(s);
  alloc_string(this, len);

  for (char *i = begin; *s != '\0'; i++, s++)
    *i = *s;
}

TString::TString(TString &&other) noexcept
    : begin(other.begin), len(other.len), tracker_index(other.tracker_index) {
  other.tracker_index = 0;
  other.begin = nullptr;
  other.len = 0;
}

TString::TString(const TString &other) noexcept
    : begin(other.begin), len(other.len), tracker_index(other.tracker_index) {
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
    for (uint64_t i = 0; i < len; i++)
      *(this->begin + i) = *(other.begin + i);

    return *this;
  }

  begin = other.begin;
  len = other.len;
  tracker_index = other.tracker_index;
  if (tracker_index == 0) {
    return *this;
  }

  std::lock_guard<std::mutex> g(mut);
  tracker_queue[tracker_index - base_idx].ref_count++;
  return *this;
}

uint64_t TString::size() const noexcept { return len; }

TString TString::substr(uint64_t idx, uint64_t len) const noexcept {
  if (len == 0) {
    return TString();
  }

  assert(idx < size());
  assert(idx + len <= size());

  TString t;
  t = *this;
  t.begin += idx;
  t.len += len;
  return t;
}

char &TString::front() noexcept { return *begin; }
const char &TString::front() const noexcept { return *begin; }
char &TString::back() noexcept { return *(begin + len - 1); }
const char &TString::back() const noexcept { return *(begin + len - 1); }

bool operator==(const TString &a, const TString &b) noexcept {
  if (a.begin == b.begin && a.len == b.len)
    return true;

  if (a.size() != b.size())
    return false;

  return strncmp(a.begin, b.begin, a.size()) == 0;
}

bool operator==(const TString &a, const char *bc) noexcept {
  if (bc == nullptr && a.begin == nullptr)
    return true;
  if (bc == nullptr)
    return false;

  return strncmp(a.begin, bc, a.size()) == 0;
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

  strncpy(t.begin, a.begin, a.size());
  strncpy(t.begin + a.size(), b.begin, b.size());

  return t;
}

TString operator+(const TString &a, const char *bc) noexcept {
  TString t;
  if (bc == nullptr) {
    t = a;
    return t;
  }

  uint64_t bc_size = strlen(bc);
  alloc_string(&t, a.size() + bc_size);

  strncpy(t.begin, a.begin, a.size());
  strncpy(t.begin + a.size(), bc, bc_size);

  return t;
}

TString operator+(const char *ac, const TString &b) noexcept {
  TString t;
  if (ac == nullptr) {
    t = b;
    return t;
  }

  uint64_t ac_size = strlen(ac);
  alloc_string(&t, b.size() + ac_size);

  strncpy(t.begin, ac, ac_size);
  strncpy(t.begin + ac_size, b.begin, b.size());

  return t;
}

std::ostream &operator<<(std::ostream &os, const TString &tstring) noexcept {
  for (uint64_t i = 0; i < tstring.len; i++)
    os << *(tstring.begin + i);
  return os;
}
