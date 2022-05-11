---
title: Building a Domain-Specific Language
categories: [bugs-nyu, yacs]
tags: [writeup,new-lang,ideas]
---
So I'm trying to build a declarative language to describe course prerequisites.
Here's my process. Also, I'm doing this while watching [this video][kernighan] on loop.

<!--
https://stackoverflow.com/questions/17313929/how-do-i-split-up-an-argument-string-bash-style-in-ruby
myh = Hash.new { |h,k| k } -->
[kernighan]: https://www.youtube.com/watch?v=Sg4U4r_AgJU

## Rationale
Course prerequisites can be strange and malleable. Sometimes the graph of
prerequisites cannot be represented as a tree because some courses are
co-requisites. Other times courses do not directly depend on a clearly defined
set of other courses, but a malleable category of courses and subjective
qualities (i.e. department approval required or 3 relevant courses required).
Because courses prerequisites are not necessarily easily evaluated, this
language aims to create a simple but expressive ruleset that works for
essentially any type of prerequisite while still being both machine and human
readable.

## Description of the Problem Space
So the purpose of the language is to make it easier to describe prerequisites of
a course to a machine. The current language that's used looks something like this:

```
Prerequisites: MATH-UA 123 Calculus III or MATH-UA 213 Math for Economics III
(for Economics majors) with a grade of C or better and/or the equivalent,
and MATH-UA 140 with a grade of C or better and/or the equivalent.
Not open to students who have taken MATH-UA 235 Probability and Statistics.
```

How do we make this *machine readable?* We can try something like this:

```python
class NumericalAnalysIsRequirements(Prerequisite):
    def __init__(self):
        self.calc = ['MATH-UA 123','MATH-UA 213']
        self.lin_alg = 'MATH-UA 140'
    def can_take(self, courses):
        if self.lin_alg not in courses:
            return False
        for course in self.calc:
            if course in courses:
                return True
        return False
```

But the people that'll be writing this language will probably
not be engineers, or familiar with computer science at all really. So the syntax
won't really benefit from following the more technical syntax of programming
languages.

Additioanlly though, it has to still be expressive enough to cover something like this:

```
Prerequisite: one introductory course.
```

or this:

```
Prerequisites: two relevant courses or approval from department.
```

Which would be absolutely awful and almost completely unreadable with some kind of
simple boolean algebra. So what we're aiming for is for the language to be:

* Easy to read and write by humans without a programming background
* Expressive enough to cover weird use cases
* Easy-ish to read for a computer

#### The Idioms of the Domain
What it really means for a language to be "easy to read" is that reading it is
as close as possible to reading natural language, or in this case, the natural
language of the domain. So to reduce the learning curve for people that use this
language, we want to use the idioms/language of the people that usually write the
prerequisites. So for example, we want the code for

```
Prerequisites: MATH-UA 123 Calculus III or MATH-UA 213 Math for Economics III
(for Economics majors) with a grade of C or better and/or the equivalent,
and MATH-UA 140 with a grade of C or better and/or the equivalent.
Not open to students who have taken MATH-UA 235 Probability and Statistics.
```

to be as close as possible to the original thing. From the above example,
two things become pretty clear:

1. Booleans are the primary data type
2. Names can include spaces

The first is pretty obvious; the eventual output is a boolean, and each course
name ultimately has a truth value when evaluating the expression. The second
is a direct result of our goal of making code look like the domain's original
natural language. Names in prerequisite strings almost always are multiple
words long.

Additionally, it's also pretty clear that operators will probably have to include
spaces as well. While the greater-than and less-than symbols might make sense
to someone familiar with programming languages in general, the end-user of this
language won't necessarily be familiar with programming languages. For example,
to represent the prerequisite `two relevant courses` from earlier, we might
want to write:

```
count(PHIL-UA 1, PHIL-UA 3, PHIL-UA 6, PHIL-UA 7) >= 2
```

However, while this might make sense a programmer, it's not the easiest to read
for people that aren't. What we really want is something closer to this:

```
at least 2 of (PHIL-UA 1, PHIL-UA 3, PHIL-UA 6, PHIL-UA 7)
```

However, words like `at`, `least`, and `of` are regularly used in course names.
If we include these as reserved words, we'd either have to do a lot more work parsing
the code, or make the writer spend more effort following some kind of syntax rule.
So the principles that we should use to drive the development of this language are:

* Readable
  - Names should be able to include spaces
  - Operators should also include spaces
* Simple
  - Shouldn't have weird symbols with important semantic meaning
  - In general, language should have minimal, predictable syntax
* Abstracted
  - Implementation shouldn't be considered when writing in this language
  - The language should just *work*, without the need for anything crazy

So in essence, we're writing a declarative language with syntax that models
the English of boolean logic.

## How the Language Spec. Should be Written
Another thing that I think is important, regardless of the eventual way the syntax
turns out, is that the **description of the language imply the interpreter's implementation.**
If the implementation of the language uses a different control flow than the language
specification, language implementation becomes harder. Also, a language spec. that
makes the order of interpretation clear makes it easier for users to debug their own
code. When writing the language specification, the presentation should imply a
very clear approach to its implementation, while still remaining machine agnostic.

## Language Design
So we're going to need some way to distinguish names from syntax. I think the
easiest way is to use quotes:

```python
Prerequisites: 'MATH-UA 123 Calculus III' and "MATH-UA 235 Probability and Statistics".
```

Additionally, we want to make sure that the syntax is pretty close to the domain's
language, so this should also be acceptable,

<div class="highlight">
<pre class="highlight">
<code><span class='n'>Prerequisites:</span> <span class='s'>MATH-UA 123 Calculus III</span> <span class='ow'>and</span> <span class='s'>MATH-UA 235 Probability "and" Statistics</span><span class='n'>.</span></code>
</pre>
</div>

...since in reality nobody puts quotes around every proper noun. We also want
whitespace to be *almost meaningless*; the above should mean the same thing even
if it's written like this:

{% capture code %}
<span class='n'>Prerequisites:</span>
  <span class='s'>MATH-UA 123 Calculus III</span>
  <span class='ow'>and</span> <span class='s'>"MATH-UA 235 Probability and Statistics"</span><span class='n'>.</span>
{% endcapture %}
{% include custom-code-block.html code=code %}

because that's how spacing works with text wrapping when we read normally. The
writer shouldn't have to worry about indentation when writing, it should be handled
for them. Also, the above should be the same thing as this:

{% capture code %}
<span class='n'>Prerequisites:</span>
  <span class='s'>MATH-UA 123   Calculus III</span>
  <span class='ow'>and</span> <span class='s'>MATH-UA  235 Probability "and" Statistics</span><span class='n'> .</span>
{% endcapture %}
{% include custom-code-block.html code=code %}

because it would be the same thing to a reader. Quotes don't have any 'special'
meaning in this context; they only signal to the interpreter that the word should
be evaluated as a string instead of an operator. Thus, there should be no problem
with using single and double quotes liberally:

{% capture code %}
<span class='n'>Prerequisites:</span>
  <span class='s'>MATH-UA 123   Calculus III</span>
  <span class='ow'>and</span> <span class='s'>"MATH"-UA  "235" Probability "and" Statistics</span><span class='n'> .</span>
{% endcapture %}
{% include custom-code-block.html code=code %}

With these rules we have an implicit order of execution: the interpreter needs to
first handle spacing, then parse strings, then it can start looking at words and
evaluate them as operators or booleans.

Additionally, while we should allow the writer to be fast and loose with spacing,
there should still be *a little* structure to spacing. For example, sentences rarely,
if ever, start in one paragraph and end in another. So a double newline should
end an expression in the same way that a period would in a normal sentence:

```python
Prerequisites: 'MATH-UA 123 Calculus III' # Should throw a syntax error

and "MATH-UA 235 Probability and Statistics".
```

On that note, *the period should be used to indicate the end of a complete thought.*
Periods are the signifier of complete thoughts in English, so they should be the
signifier in this language too. But additionally, I think, there should be another,
just for convenience: the semicolon. Semicolons signify complete thoughts just like periods,
albeit with an implicit relationship to the next thought. Since every statement in
this language will likely be related to the previous semantically (as a 'program'
will always be describing the prerequisites of a single course),
semicolons essentially have the same semantic meaning in this language as they
do in English. Also, I'm used to semicolons from Java.

Additionally, the last sentence of a paragraph or book is the last sentence
regardless of whether it ends with punctuation or not; that should be true here too. All
of the above could have been written without a period, and still would have made sense.
Thus, there should always be an implicit period/semicolon at the end of the script/program.

I think we're almost done, But we're missing a few things. First of all, we still
don't really cover the third example from earlier:

```
Prerequisite: two relevant courses.
```

To handle this case, we need to add lists, so that we can write the above as
something like this:

{% capture code %}
<span class='n'>Prerequisites:</span> <span class='mi'>2</span> <span class='ow'>of</span>
  <span class='n'>(</span>
    <span class='s'>PHIL-UA 1</span><span class='n'>,</span>
    <span class='s'>PHIL-UA 3</span><span class='n'>,</span>
    <span class='s'>PHIL-UA 6</span><span class='n'>,</span>
    <span class='s'>PHIL-UA 7</span>
  <span class='n'>).</span>
{% endcapture %}
{% include custom-code-block.html code=code %}

<div class="highlight">
<pre class="highlight">
<code></code>
</pre>
</div>

We should also add in variables so that this would also work:

{% capture code %}
<span class='n'>relevant courses =</span>
  <span class='n'>(</span>
    <span class='s'>PHIL-UA 1</span><span class='n'>,</span>
    <span class='s'>PHIL-UA 3</span><span class='n'>,</span>
    <span class='s'>PHIL-UA 6</span><span class='n'>,</span>
    <span class='s'>PHIL-UA 7</span>
  <span class='n'>);</span>
<span class='n'>Prerequisites:</span>
  <span class='mi'>2</span> <span class='ow'>of</span> <span class='s'>relevant courses</span><span class='n'>.</span>
{% endcapture %}
{% include custom-code-block.html code=code %}

And now our final statement looks almost exactly like the original prerequisite!
That's exactly what we're going for.

## Wrapping Up
I think we've gotten to the point where the language will write itself.
I'm going to start writing these features down, and then write a post describing
the syntax of the language as if for a manual for the end-user, and then also
write another post describing the implementation, with the intent being that the
two could be read side-by-side and make sense.
