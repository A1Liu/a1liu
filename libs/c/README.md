# Helper Files in C
Here's a set of helper files I wrote in C.

- `debug_allocator.h`/`debug_allocator.c` - Exports the following macros:

  - `malloc` - Wrapper around the standard `malloc` that records file and line number
  - `free` - Wrapper around the standard `free` that records file and line number
  - `realloc` - Wrapper around the standard `realloc` that records file and line number
  - `check` - Checks that the pointer given is safe to dereference, and then returns it.
    Usage: `check(ptr)->field`

- `dyn_array.h`/`dyn_array.c` - The equivalent of `std::vector` in C++, or `Vec`
  in Rust.
- `bump_list.h`/`bump_list.c` - A linked list of bump allocators.
