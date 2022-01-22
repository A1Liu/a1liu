title: Software disenchantment
source: https://tonsky.me/blog/disenchantment/

Look around: our portable computers are thousands of times more powerful than
the ones that brought man to the moon. Yet every other webpage struggles to
maintain a smooth 60fps scroll on the latest top-of-the-line MacBook Pro. I can
comfortably play games, watch 4K videos, but not scroll web pages? How is that
ok?

Google Inbox, a web app written by Google, running in Chrome browser also by
Google, takes 13 seconds to open moderately-sized emails:

It also animates empty white boxes instead of showing their content because
it’s the only way anything can be animated on a webpage with decent
performance. No, decent doesn’t mean 60fps, it’s rather “as fast as this web
page could possibly go”. I’m dying to see the web community answer when 120Hz
displays become mainstream. Shit barely hits 60Hz already.

Windows 10 takes 30 minutes to update. What could it possibly be doing for that
long? That much time is enough to fully format my SSD drive, download a fresh
build and install it like 5 times in a row.

    Pavel Fatin: Typing in editor is a relatively simple process, so even 286
    PCs were able to provide a rather fluid typing experience.

Modern text editors have higher latency than 42-year-old Emacs. Text editors!
What can be simpler? On each keystroke, all you have to do is update a tiny
rectangular region and modern text editors can’t do that in 16ms. It’s a lot of
time. A LOT. A 3D game can fill the whole screen with hundreds of thousands
(!!!) of polygons in the same 16ms and also process input, recalculate the
world and dynamically load/unload resources. How come?

As a general trend, we’re not getting faster software with more features. We’re
getting faster hardware that runs slower software with the same features.
Everything works way below the possible speed. Ever wonder why your phone needs
30 to 60 seconds to boot? Why can’t it boot, say, in one second? There are no
physical limitations to that. I would love to see that. I would love to see
limits reached and explored, utilizing every last bit of performance we can get
for something meaningful in a meaningful way.

--------------------------------------------------------------------------------

title: The need for speed
source: https://www.nngroup.com/articles/the-need-for-speed/

You might be wondering whether people simply don’t notice how much faster
today’s sites are because their expectations have increased over time. While
it’s true that people’s estimates of wait times are sometimes exaggerated, in
this case it’s not just a matter of distorted perceptions.

For the past 10 years, Httparchive.org has recorded page load times for 6
million popular websites. (Httparchive.org is a part of the
InternetArchive.org, whom you may know as the folks behind the WayBack
Machine). The results are not encouraging: for webpages visited from a desktop
computer, the median load time hasn’t improved. Today’s websites aren’t that
much faster than they were 10 years ago.  Line chart showing change from 2010
to 2019 in median page load time and in the average internet connection speed

As you might guess, the story on mobile is even worse — connection speeds have
improved for sure, but, over the past 10 years, the mobile page load times
tracked by Httparchive have actually increased.  Chart showing the change from
2011 to 2019 in the average page load time on mobile devices vs. the average
mobile device internet connection speed The average connection speed for U.S.
mobile users has increased steadily in the past 10 years; meanwhile, the load
times for mobile web pages over the same period have more than doubled.
Connection speed data through 2017 is from Akamai (which in 2014 adjusted its
methodology to record connection speeds from a larger sample of devices); data
from 2018 and 2019 is from Opensignal.com, a mobile analytics company. Page
OnLoad times for mobile webpages are as recorded by Httparchive.org.

Increases in internet speed clearly haven’t solved the problem of slow
websites. Of course, network speed is not the only factor that affects
performance, so it’s not reasonable to expect speeds to have completely kept
pace with network connectivity. But it seems like huge increases in network
speed should make it at least somewhat faster to browse the web.

You may be wondering if this data is really accurate, which is a fair question,
as there are many different ways to measure performance and speed, such as by
sampling different selections of websites or using different milestones to
identify when a page is loaded. For example, in 2018, Google reported an
average time of 7 seconds for mobile pages to load content above the fold. But,
since above-the-fold loading times from 10 years ago aren’t available, we can’t
draw conclusions about trends in that particular metric. In any case, even this
more favorable number is still 7 times slower than the recommended response
time for navigating web pages.) The Httparchive.org data is unique in that it’s
been collected using the same approach for the entire decade, allowing
longitudinal comparison. This data strongly suggests that the websites people
encounter today aren’t that much faster than they were a decade ago.

--------------------------------------------------------------------------------
