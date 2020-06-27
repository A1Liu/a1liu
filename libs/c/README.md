# Helper Files in C
Here's a set of helper files I wrote in C.

- `debug_allocator.h`/`debug_allocator.c` - Exports the following macros:

  - `malloc` - Wrapper around the standard `malloc` that records file and line number
  - `free` - Wrapper around the standard `free` that records file and line number
  - `realloc` - Wrapper around the standard `realloc` that records file and line number
  - `check` - Checks that the pointer given is safe to dereference, and then returns it.
    Usage: `check(ptr)->field`

  The memory allocated by this allocator is buffered by 2 times the requested size
  at either end; that means an allocation of 16 bytes actually will allocate 80,
  and the pointer returned will be at byte 32.

  The memory in the buffer zones is initialized to the value `0xaabcdeff`, while
  the memory in the allocation itself is initialized to the value `0xdadfaded`.
  After being freed, the memory in the buffer zones gets set to `0xbadadded`, which
  the memory in the allocation itself is set to the value `0xdeadbeef`.

- `dyn_array.h`/`dyn_array.c` - The equivalent of `std::vector` in C++, or `Vec`
  in Rust.
- `bump_list.h`/`bump_list.c` - A linked list of bump allocators.
