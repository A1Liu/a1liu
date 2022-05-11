---
title: Explicit Captures for Closures and Code Blocks in Rust
categories: [bugs-nyu, yacs]
tags: [language-design]
---
<!-- {% raw %} -->
<!-- {% include refc-small.html text="ref commit" commit="3cad965..." %} -->
<!-- {% include ref-commit.html text="ref commit" commit="3cad965..." %} -->
<!-- {% endraw %} -->
In [his second video on a games programming language][jai-video-two],
Jonathan Blow discusses the concept of C++ captures in its lambda syntax,
and the potential generalization of the capture syntax to any block.
I think that this feature would be useful to implement in Rust for the following reasons:

[jai-video-two]: https://youtu.be/5Nc68IdNKdg?t=3030

1. Additional type safety with low compile-time overhead:
   if the programmer explicitly states the namespace of the closure,
   the compiler has an easier job of labeling everything in that namespace as moved/borrowed/etc.
   depending on the information the user provided.
2. Additional information for the compiler: the programmer can use the syntax to
   explicitly state that the code block doesn't modify global state,
   i.e. its a pure function, without requiring the compiler to do any analysis beside namespace checking.
3. Faster testing and code factoring: Jon states in his video that using this syntax
   could make it easier to prototype the movement of a code block out of a larger
   function and into a smaller utility function. This is even more true of Rust;
   we already have block expressions, so adding a syntax to limit the namespace
   of a block would just make it easier to move blocks into their own function.
4. Readability without comments: the syntax would give future readers additional
   information about the function and its side effects, in a way that can be
   validated by the compiler. i.e. we can have a compile-time guarrantee that certain
   functions do not and cannot change global state.

The syntax could be implemented using a similar syntax to that discussed in the video:

```rust
pub fn long_monolithic_function(state: GlobalState) -> GlobalState {
    // Here we're using a capture in square brackets
    // to say that we only want to operate on 2 members of the input struct,
    // with mutation on one, and rename them for easier processing
    let mut result: u64 = [&state.data as data, &mut state.other as other] {
        other += 1;

        // We use the empty brackets to state that global/non-local state
        // isn't used here, and its a pure function
        data.iter().map(|item| [] {
           // Complicated stuff here
           // Lots of logic
        })
        .sum()
    }
    // do work with result here
    // ...
    // ...
    state
}

pub fn my_function(foo: String) -> bool [&bar] {
    // do work on foo, while reading the state of bar
    // ...
    bar.validate(foo)
}
```
There are a few potential downsides to this idea:

1. Additional complexity of the language: the language by definition becomes more
   complex.
2. Worse compilation times in the general case: its hard to say for certain, but
   certainly if nobody uses the feature the compiler will just be objectively slower.
3. Questionable necessity: the existing syntax and borrow-checking system might
   sufficient to give the guarantees that this proposal aims to provide. For the
   person writing the code this feature is absolutely unnecessary; the borrow-checker
   already does the checks to see if your closure/block does things that aren't memory
   safe. Something like this would be objectively useful in a language with less
   static analysis, but here its use case may already be covered.
4. Unclear syntax: it's unclear how the syntax should actually look. The above version
   of the syntax is not binding by any means.
5. Unclear implementation: this idea might require lost of changes to the way that
   namespaces are currently handled internally.
