---
title: BUGS EBoard Meeting Notes
categories: [bugs-nyu]
tags: [yacs, ideas, meeting, eboard]
---
These are my meeting notes for the first BUGS EBoard meeting of the Spring semester.
Since I couldn't attend the meeting, this is the best I could do `:(`.
{% capture top %}<small><a name="" href="#">back to top</a></small>{% endcapture %}

[Skip to Website Info](#website-info)

## YACS Updates and Briefing
This section serves both as an update to the current status of YACS, as well as
a briefing for ShiXuan (Shelly) and Brian, our new Director and Vice Director
of Outreach. If you'd like to skip to the new information, it's in the
[new information section](#yacs-new-info).

#### Basic Concepts
Yet Another Course Schedule (YACS) is an open source course scheduler, and is
currently the de facto course schedule for students at Rensselaer Polytechnic
Institute (RPI). It's currently hosted by the Rensselaer Center for Open Source (RCOS)
and led by Ada Young, who is currently working on integrating NYU course
information into the YACS infrastructure, so that NYU students will have a genuine
graphical interface to schedule their courses.

#### Progress Last Semester {{ top }}
Bradley and I organized a small group of NYU students to build an "adapter",
which is the term used to describe an HTTP endpoint that responds to YACS HTTP
requests with course information. Our team first built a Python script to collect
information from Gallatin's public API (which may or may not be outdated). Then,
we began work on a scraper to collect course information from NYU's
[Class Search][albert-class-search]. Work slowed as the semester progressed, and
eventually came to a grinding halt by early November, as students began to fall
behind with learning the necessary Python syntax and networking protocols to meaningfully
contribute or even understand the existing codebase.

Around this time, Bradley was contacted by a student at WSN about the project.
The interview led to some minor publicity about BUGS and YACS, but more importantly
it got the attention of people at the registrar. As a result, Bradley and I met
with the NYU administrators responsible for maintaining NYU Albert, and discussed
the viability of YACS being integrated into NYU. For more information on the result
of the meeting, [see our post in the Eboard Slack][eboard-post]; the gist is that
Our jobs probably got way easier. Hopefully this means that by Fall 2019, we’ll
have a system ready to help NYU students schedule their courses.

[albert-class-search]: https://m.albert.nyu.edu/app/catalog/classSearch
[eboard-post]: https://bugs-mentors.slack.com/archives/G97EZ3D7F/p1544817503000200

#### Resources for More Information {{ top }}
- [YACS User-Facing Website][nightly-yacs] - the website that RPI students use to schedule courses
- [Documentation][yacs-docs] - More information on contributing to YACS/using its API
- [Github Repository][yacs-repo] - Source code
- [NYU Team Slack][nyu-slack] - The Slack workspace for the team that Bradley and I organized
- [RCOS Team MatterMost][rcos-mattermost] - The MatterMost workspace that RCOS students use
- [Planning Doc for Spring 2019][rcos-dropbox-paper] - The DropBox document that holds information
relevant to the planning of YACS. The ultimate audience for this doc is RCOS administration

[nightly-yacs]: https://nightly.yacs.io/
[yacs-docs]: https://yacs.io/#/
[yacs-repo]: https://github.com/YACS-RCOS/yacs
[nyu-slack]: https://yacsnyu.slack.com/
[rcos-mattermost]: https://chat.rcos.io
[rcos-dropbox-paper]: https://paper.dropbox.com/doc/YACS-Spring-2019-The-Bester-Semester-Ever-gWZcv5kjBK3BbKcQXM4ST

<a name="yacs-new-info"></a>
#### New Information {{ top }}
Firstly, the YACS workflow has moved to [MatterMost][rcos-mattermost]; the NYU students
that originally showed interest in working on YACS are still in the Slack, and so
we can't just ignore it, but we should migrate our own workflow to their MatterMost
to make it easier to collaborate.

Additionally, this past week Ada and I developed, and [nearly completed][pr-nyu-adapter],
the class search adapter. Thus, the work that NYU students can contribute to the
project is the following:

- **Helping with existing tasks** - Tasks on the [planning doc][rcos-dropbox-paper]
like front end development using Angular
- **Improving Documentation** - The docs aren't the greatest as of now; for example,
the database layout is all but undocumented.
- **Talking to the Registrar** - This is the big one. We want to keep an open line of
communication with the registrar to make it as painless to implement YACS at NYU
as possible. For example, we found a problem with the NYU Class Search that results
in a 2X slowdown for students, and also our course scheduler. If we could somehow
get NYU IT to solve the problem on their end, it would improve the search experience
for NYU students and also reduce the complexity of our scraper.

[pr-nyu-adapter]: https://github.com/YACS-RCOS/yacs/pull/392

<a name="website-info"></a>
## Club Website {{ top }}
I don't really know what we're trying to accomplish with the website, so I've been
trying to stay away from redesigning anything. That is, are we trying to...

- Create an example of open source web design
- Advertise to students
- Advertise/demonstrate proficiency to NYU administrators
- Build a home-base for students that want to interact with the club
- Make it easier to communicate to members
- Build a student resource for entering and succeeding in open source
- Do something else?

Right now I'm working on refactoring the existing code to follow the idioms of
Bootstrap webpages, i.e. the grid system and custom classes. But in the near future
the question of what to work on will be highly dependent on what our eventual goal
for the website is. Right now there are a few problem areas:

- News and Connect pages are graphically broken
- No documentation of the site repository's structure
- No consistent style for existing code
- Minimal content on the site
- Minimal community around its improvement

The order that we address these problems should depend on what we want the website
to do, and so I'd like to figure that out before we start brainstorming redesigns.
Also, once we have an idea of the general purpose of the site, if anyone has any
ideas on any of the following, I'd be happy to open an issue and start working on
integrating them:

- Overall design of the site
- Features and new pages
- IRC/Discord Server (this is on the TODO but idk what it means)
- Increasing the amount of content on the site (e.g. blogging? More regular news posts?)
