# WWW::Chain House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; judgment on trivial ones. Loaded automatically at launch (same
priority as `CLAUDE.md`). Subagents get their conventions from the skills force-loaded via
`briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum change that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments or formatting. Match existing style.
4. **Read before you write** — The protocol (`parse_chain` / `next_responses` / `BUILD`)
   and the `WWW::Chain::UA` role are one contract; read both callers and the hand-fed
   tests before touching either.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), say why, flag the other. Don't blend.
6. **Checkpoint after every significant step** — done / verified / left.
7. **Fail loud** — "Done" is wrong if anything was skipped silently; "tests pass" is wrong
   if the loopback (`Test::HTTP::Server`) tests were skipped rather than run.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate.

  | Task | Agent |
  |---|---|
  | lib/WWW/, t/, the chain protocol, the UA role and its LWP backend | `www-chain-worker` (default) |
  | Commits, `Changes`, card → done, pre-release audit | `www-chain-release-manager` |

  Your lane: coordinate, inspect, plan, review diffs, run tests, write
  `Changes` notes and prose docs. When in doubt, delegate. Why: only the `www-chain-*`
  agents get `www-chain-core` / `getty-perl-moo` force-loaded via `briefing.skills`; you
  get no briefing and would touch the protocol with too little context.
- **You cannot spawn subagents** (you ARE a `www-chain-*` agent): the lock does not
  apply — implement, refactor, debug and test per these rules.

Behavior-relevant = anything changing what the chain does or how a UA runs it:
`lib/WWW/Chain.pm`, `lib/WWW/Chain/UA.pm`, `lib/WWW/Chain/UA/LWP.pm`, `cpanfile`,
`dist.ini`, `t/`. Prose and `Changes` notes are not.

**Only `www-chain-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `www-chain-release-manager` to cut the commit and close the card.

## Project hazards — why this file is worth loading

- **The `die`s in `next_responses` are the contract, not defensive noise.** Exact
  response count, `HTTP::Response`-only, and not-when-`done` are guarantees callers rely
  on; a green test after weakening one proves nothing — keep `t/10-base.t` and
  `t/30-methods.t` (both socket-free) passing on any protocol change.
- **`www_chain` takes a coderef step only; subclass mode takes method-name strings.**
  `parse_chain` accepts both a `CodeRef` and a `->can`-able `Str`, but the exported
  `www_chain` builder rejects a string step — don't "unify" them without knowing why.
- **Skills under `.claude/skills/` are hardlinks** to `~/dev/skills/…` and `~/dev/karr/…`.
  Never `Edit`/`Write` one — rewrite in place (`cat > path <<'EOF'`), or every other repo
  silently keeps the old content. `manage-skills check` verifies, `manage-skills sync`
  repairs. `www-chain-core` is project-owned and edited normally.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban, state in
`refs/karr/*` of this repo: `karr board` / `karr list --compact` to see open work,
`karr create "Title" --priority high`, `karr move ID in-progress --claim NAME`,
`karr handoff ID --claim NAME`. Full surface: that skill.

**Serialize board mutations when fanning out**: implementation may run parallel, the
`karr move`/`handoff`/`sync` calls run sequentially — N landing at once is a resource
event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are
STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan lists
"release" as the next step. Pre-release audit goes through `www-chain-release-manager`.

## Public issues (GitHub) — never act without instruction

**karr** is the internal agent board, churned freely. **GitHub issues**
(`github.com/Getty/p5-www-chain`) are the public tracker: real humans, published under
the maintainer's account. Never act on one on your own initiative — not even to read it —
unless the user points at a specific item.

## Perl and Moo specifics — reference, don't restate

House Perl style: skill `getty-perl-core`. Moo idioms: skill `getty-perl-moo`. This
distribution's protocol and UA role: skill `www-chain-core`. Do not duplicate them here.
