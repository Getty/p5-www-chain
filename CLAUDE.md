# WWW::Chain

A Moo-based library for chaining HTTP requests: a `WWW::Chain` object fires a batch of
`HTTP::Request`s, hands the `HTTP::Response`s to a step callback, and repeats with whatever
that step returns until a step returns no request. Requests run through a
`WWW::Chain::UA` — the shipped backend is `WWW::Chain::UA::LWP` (blocking, over
`LWP::UserAgent`); a caller can also drive `next_requests`/`next_responses` by hand for
non-blocking use. The chain protocol, the UA role and the authoring modes are in skill
`www-chain-core`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/www-chain-rules.md`.

| Task | Agent |
|---|---|
| lib/WWW/, t/, the chain protocol, the UA role and its LWP backend | `www-chain-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-chain-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Tickets live on the repo's `karr` board.

## Skills

`www-chain-core` is project-owned; every other skill under `.claude/skills/` is a hardlink
into the shared library — `manage-skills sync` re-establishes the links after a fresh
clone, and a hardlinked `SKILL.md` is edited in place, never with `Edit`/`Write`.

| Skill | Covers |
|---|---|
| `www-chain-core` | this distribution: the chain protocol, the UA role, coderef vs subclass mode, the test layout |
| `getty-perl-moo` | Moo classes, roles, attributes, lifecycle |
| `getty-perl-core` | house Perl conventions |
| `getty-perl-release-author-getty`, `perl-release-dist-ini` | the `[@Author::GETTY]` bundle and `dist.ini` |
| `kanban-issues-karr-coordination` | the karr board |
