# User instructions

Standing preferences that apply to every repo I work in, not just this one.
Lives in `a1liu/.agents/USER_AGENTS.md` and is linked to `~/.claude/CLAUDE.md`,
so edits here apply to every Claude Code session on this machine right away.

## Git and pull requests

- Check the branch situation before starting: fetch `origin/main` and compare.
  Local branches go stale; base new work on `origin/main`.
- Finish code tasks with a commit, a push, and a pull request. That's the
  default — don't stop to ask whether I want one.
- One pull request per logical change. When a task has an orthogonal refactor
  in it, that refactor is the base and the feature stacks on top.
- Keep pull request descriptions to a short summary plus whatever testing was
  done. Say each thing once; the diff is already there to read. A stacked pull
  request's description is just `Stacked on #N`.
- Don't comment on pull requests. Notes about my own work go in the
  description. When responding to someone else's review, change the code and
  leave the thread alone.

## Writing

- Don't create or edit documentation unless I asked for it. If a change makes
  an existing document wrong, say so and leave the file alone.
- Code comments describe what the code does now, never what it replaced or how
  it used to work. Prefer a link to context over copying the context in.

## Code

- Look for an existing library before hand-rolling. Check what the repo already
  depends on first.
- Generated files -- lock files, resolved dependencies, anything a tool emits --
  get regenerated with that tool, never hand-edited. If the tool can't run, say
  so and leave the file alone: a missing entry fails loudly, a plausible wrong
  one doesn't.
