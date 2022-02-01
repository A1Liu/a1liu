# Posix Tricks

## Online Documentation
There's a lot of incorrect/outdated information out there for Linux stuff.
Oftentimes it seems that the best solution is to simply restart the computer,
and make sure drivers are both up-to-date and being activated correctly. Also,
internet sources seem to be even more unreliable and unhelpful for Linux stuff
than for other CS things, so its good to be specific about what system you're on.

## Hostname Aliases
The file `etc/hosts` allows you to alias hosts, so that local development is
easier. For example, you can alias `schedge.local` to `127.0.0.1`, and then
when you write the full URL in your browser, it'll learn to auto-complete the
full URL, including the port number.

## Linux Software
- Input Remapper: https://github.com/sezanzeb/input-remapper
