# Helper Files in C
Here's a set of helper files I wrote in C.

- `debug_allocator.h`/`debug_allocator.c` - A wrapper around `malloc` and `free`
  that tracks your allocations. Also includes a macro that checks whether a pointer
  is valid before you dereference it, so instead of `ptr->field`, you can do
  `check(ptr)->field`.
