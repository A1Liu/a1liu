title: The Fallacy of Premature Optimization
source: https://ubiquity.acm.org/article.cfm?id=1513451

What Hoare and Knuth are really saying is that software engineers should worry
about other issues (such as good algorithm design and good implementations of
those algorithms) before they worry about micro-optimizations such as how many
CPU cycles a particular statement consumes.

It is interesting to look at how some software engineers have perverted those
good software engineering concepts to avoid the work associated with writing
efficient code.

Observation #1: "Premature optimization is the root of all evil" has become
"Optimization is the root of all evil." Therefore, optimization should be
avoided.

Observation #2: Many software engineers believe that optimization is the act of
ensuring an application has adequate performance. As a result, those engineers
do not consider application performance during the design of the software, when
it is critical to do so.

Observation #3: Software engineers use the Pareto Principle (also known as the
"80/20 rule") to delay concern about software performance, mistakenly believing
that performance problems will be easy to solve at the end of the software
development cycle. This belief ignores the fact that the 20 percent of the code
that takes 80 percent of the execution time is probably spread throughout the
source code and is not easy to surgically modify. Further, the Pareto Principle
doesn't apply that well if the code is not well-written to begin with (i.e., a
few bad algorithms, or implementations of those algorithms, in a few locations
can completely skew the performance of the system).

Observation #4: Many software engineers have come to believe that by the time
their application ships CPU performance will have increased to cover any coding
sloppiness on their part. While this was true during the 1990s, the phenomenal
increases in CPU performance seen during that decade have not been matched
during the current decade.

Observation #5: Software engineers have been led to believe that they are
incapable of predicting where their applications spend most of their execution
time. Therefore, they don't bother improving performance of sections of code
that are obviously bad because they have no proof that the bad section of code
will hurt overall program performance.

Observation #6: Software engineers have been led to believe that their time is
more valuable than CPU time; therefore, wasting CPU cycles in order to reduce
development time is always a win. They've forgotten, however, that the
application users' time is more valuable than their time.

Observation #7: Optimization is a difficult and expensive process. Many
engineers argue that this process delays entry into the marketplace and reduces
profit. This may be true, but it ignores the cost associated with
poor-performing products (particularly when there is competition in the
marketplace).

Observation #8: The most fundamental rule software engineers cite when
performance is a concern is "choosing the proper algorithm is far more
important than any amount of (micro-) optimization you can do to your code."
This ignores the fact that a better algorithm might not be available or may be
difficult to discover or implement. In any case, this is not a good excuse for
creating a poor implementation of any algorithm.

Observation #9: There is little need to ensure that you have the best possible
algorithm during initial software design because you can always substitute a
better algorithm later. Therefore, there is no need to worry about performance
during initial software design because it can always be corrected with a better
algorithm later. Unfortunately, people who take this approach to software
design often write code that cannot be easily modified down the road.

--------------------------------------------------------------------------------

