---
title: CAS Pointer to Atomically Reference Counted Data
categories: [personal]
tags: [rust, programming]
---
<!-- {% raw %} -->
<!-- {% include refc-small.html text="ref commit" commit="3cad965..." %} -->
<!-- {% include ref-commit.html text="ref commit" commit="3cad965..." %} -->
<!-- {% endraw %} -->
The problem I'd like to solve is this: lets say that I have some heap-allocated data
that is atomically reference counted by smart pointers. I.e.

```c++
int main() {
  auto ptr = std::make_shared<Data>();
}
```

How do I safely modify the value of `ptr` if it's shared among multiple threads?
How do I safely change what `ptr` points to while other threads are accessing
it?

#### May 20, 2019
## Initial Brainstorming

### Naively with RW-Locks
A simple first solution is to use a reader-writer lock. This can be implemented
however you see fit, but the idea is simple; only modify `ptr` when the value isn't
being read by other threads. Easy enough.

### Atomics and Problems with a Naive Implementation
The problem with the above solution is that it can be slow; *what if a bunch
of threads want exclusive write access at the same time?* Then we'd have a bunch
of waiting and not much else. Instead, we want to use some kind of atomic operation
to write to the pointer, so that other threads can't ever see an invalid state.
But the problem, as far as I can tell, is that the reference counting can't be
done atomically *at the same time* as the pointer swap; that is, if I pointer swap,
someone else might have just atomically read the pointer, but not updated the
reference count, and so they think the pointer is still valid and try to increment
the ref-count, resulting in an invalid memory access. Objects can go from valid
to invalid, but not from valid to invalid, at least not without some kind of external
synchronization first.

### "Concurrent Memory Reclamation"
I read a [blog post by Ticki][ticki-blog] about concurrent memory reclamation,
and found that modifying the value of a ref-counted pointer just isn't really possible
without a more complex system. This'll take more time than I thought.

[ticki-blog]: http://ticki.github.io/blog/fearless-concurrency-with-hazard-pointers/

#### May 22, 2019 - ...
## Research
I've gotta research a lot more. I'll document what I learn from each source as
I discover and use them.

- [Herb Sutter's Lock-Free Programming Talk][playing-with-razors] -
- [Tony Van Eerd's Basics of Lock-Free Programming Talk][basics-of-lock-free] -
- [Herb Sutter's Atomic Weapons Talk][atomic-weapons] -
- [Ticki's Hazard Pointers Post][ticki-blog] -
- [Andrei Alexandrescu and Maged Michael's Hazard Pointers Paper][hazard-ptrs] -
- [Peter Bailis's Post on Linearizability][linearizability] -

[atomic-weapons]: https://www.youtube.com/watch?v=A8eCGOqgvH4
[basics-of-lock-free]: https://www.youtube.com/watch?v=LbOB_moUa94
[playing-with-razors]: https://www.youtube.com/watch?v=c1gO9aB9nbs
[hazard-ptrs]: https://www.researchgate.net/publication/252573326_Lock-Free_Data_Structures_with_Hazard_Pointers
[linearizability]: http://www.bailis.org/blog/linearizability-versus-serializability/
