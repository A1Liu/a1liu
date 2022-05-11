---
title: Debug Allocator for C
categories: [programming]
tags: [c,programming]
---
I've made a debug allocator for the C; hopefully this will make it easier for
NYU students to learn C and debug their C programs for CSO. The files are:

-  [debug\_allocator.h](https://raw.githubusercontent.com/A1Liu/config/master/libs/c/debug_allocator.h) -
   This is the file that defines the macros that make the allocator work; you'll
   want to include it in your projects with `#include "debug_allocator.h"`.
-  [debug\_allocator.c](https://raw.githubusercontent.com/A1Liu/config/master/libs/c/debug_allocator.c) -
   This is the implementation file; it calls `malloc` and `free`, while tracking
   file and line numbers of allocations.

### Features
These two files provide the following features

-  `malloc`, `free`, and `realloc` macros - These macros are defined in `debug_allocator.h`,
   and simply call `__debug_alloc`, `__debug_dealloc`, and `__debug_realloc` respectively,
   while also passing in the file and line number they were called at.
-  Allocation tracking - `debug_allocator.c` tracks all allocations made during
   the program's execution.
-  Defined unitialized/freed values - unitialized memory is initialized with the
   value `0xdadfaded` and freed memory is overwritten with `0xdeadbeef`
-  Oversized allocations and accompanying defined values - Every allocation made
   is over-allocated by 5x, and the extra space is used as a buffer on either side
   of the allocated region. These regions are initialized to `0xaabcdeff`, and
   overwritten with `0xbadadded` on free.
-  `check` macro - This macro calls `__debug_check_alloc`, and makes sure that
   the given pointer is a valid reference to the heap. Additionally, it uses the
   allocation information given to give better error messages.

### How to Use
To use these files, first download them (and/or copy-paste them) into your project.
Usually C projects come with a source folder, often abbreviated `src`, so that's
where they should go. Then any time you need to use `malloc`, add the following
line near the beginning of the file:

```c
#include "debug_allocator.h"
```

Then, just use `malloc` normally! The macros will take care of the rest.

**Please note: don't keep these files in your project!** They're useful for
debugging, but are terrible for performance. Every deallocation is a linear scan
through the list of all allocations that you've made over the course of the program,
so ultimately a program that just allocates and then immediately deallocates a few
hundred times is quadratic.

### How it Works
This allocator doesn't do much, but what it does still might be worth explaining.

-  **Usage of Macros** - All of the macros used in this allocator make use of the
   same tools: `__FILE__` and `__LINE__`. `__FILE__` is a macro that expands to
   the name of the file it is used in, and `__LINE__` likewise expands to the
   line number of the file it is used in; this means that if `malloc(x)` expands to
   `__debug_alloc(x, __FILE__, __LINE__)`, then `__debug_alloc` will get access
   to the file and line number it was called at, which is exactly what we want.
-  **Tracking Allocations** - This allocator uses a type called `AllocVec` to
   emulate the behavior of an `ArrayList` in Java or a `vector` in C++. Every time
   you allocate, it does the equivalent of `ArrayList.add`, and when you deallocate
   it searches through the list of allocations and marks the correct allocation
   as freed.

