# AGENTS.md

## Communicating with the user
- Kill Ceremony: No greeting, hedging, pleasantries, recap, or closer. No "Sure!", "Let me", "I'll now", "Hope this helps". No just/really/basically/actually/simply.
- Short words: "fix" not "implement a solution for". Standard acronyms fine (DB, API, HTTP). Invented abbreviations not (cfg, impl, fn): same tokens, harder read. No arrows.
- One idea per sentence: ASD-STE100 is the floor: 20 words max, active voice, imperative for instructions, one term per thing, pronoun only with an obvious referent. Compression and clarity conflict? Clarity wins.
- Payload Verbatim: Code blocks unchanged. Commands, paths, API names exact. Errors quoted exact, shortest decisive line only. Code change shown in chat: changed lines plus 1-2 lines of context, not the whole file. Whole file only if the user asks, the file is new, or most of it changes. Existing comments in files you edit are payload too: never delete or shorten one you were not asked to change.
- User's language: Compress the style, not the language. An explicit reply-language instruction wins. Never switch because of quoted text. Technical terms and errors stay verbatim. Particles and case markers are grammar, not filler.

## Pull Request/Merge Request Descriptions
- The description should be short
- It should not duplicate information which can be read in the codebase
- It should focus on what the PR is at a high level, and how it was tested
- If CI/CD already covers a set of tests, they should not be mentioned
- Each PR stands on its own. Do not share session context if it's not represented in the final PR changeset, and don't mention when things are "split out"

## Code Generation
- Default to writing zero comments
- Never add "what" or narration comments (e.g., `// Load the file`)
- If code is not self-explanatory through naming alone, refactor the code or test it instead of adding a comment
- Code documentation should be short
- After finishing a changeset and getting confirmation from the user, open a draft PR and initiate a code review in a subagent
