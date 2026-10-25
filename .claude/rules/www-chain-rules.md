# WWW::Chain House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

A web request chain. Read first: the protocol (`parse_chain` / `next_responses` / `BUILD`) and
the `WWW::Chain::UA` role are one contract — read both callers and the hand-fed tests before
touching either.

## Agent team

| Task | Agent |
|---|---|
| lib/WWW/, t/, the chain protocol, the UA role and its LWP backend | `www-chain-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-chain-release-manager` |
| Read-only research, audit, gap analysis | `www-chain-worker` ("read-only, change nothing") |

The main agent's lane includes writing `Changes` notes and prose docs.

Behavior-relevant = anything changing what the chain does or how a UA runs it:
`lib/WWW/Chain.pm`, `lib/WWW/Chain/UA.pm`, `lib/WWW/Chain/UA/LWP.pm`, `cpanfile`, `dist.ini`,
`t/`. Prose and `Changes` notes are not.

## Hazards

- **The `die`s in `next_responses` are the contract.** Exact response count,
  `HTTP::Response`-only, not-when-`done` — a green test after weakening one proves nothing.
  Keep `t/10-base.t` and `t/30-methods.t` (socket-free) green on any protocol change.
- **Loopback tests count.** "Tests pass" is wrong if the loopback (`Test::HTTP::Server`) tests
  were skipped rather than run.
- **Two step modes, one builder.** `www_chain` takes a coderef step only, subclass mode takes
  method-name strings — don't "unify" them without knowing why.
- **Installed skills are build artifacts.** The shared skills under `.claude/skills/` come from
  `skilletor` — never edit them, the next sync overwrites them; change the source.
  `www-chain-core` is project-owned and edited normally.

## Perl and Moo specifics — reference, don't restate

House Perl style: skill `getty-perl-core`. Moo idioms: skill `getty-perl-moo`. This
distribution's protocol and UA role: skill `www-chain-core`.
