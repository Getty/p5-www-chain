---
name: www-chain-core
description: Use when working on the WWW::Chain distribution — the chain protocol (request list + step callback, next_responses/done), the WWW::Chain::UA role and its LWP backend, coderef vs subclass authoring, or the t/00–30 test layout.
metadata:
  type: project
---

# WWW::Chain — core

Force-loaded into every `www-chain-*` agent before its first turn; do not restate
it in an agent body. Moo house style lives in `getty-perl-moo`, general Perl house
rules in `getty-perl-core` — this file holds only what is true about *this*
distribution.

## What the distribution is

A `WWW::Chain` object drives a **multi-step HTTP conversation**: fire a batch of
`HTTP::Request`s, hand the `HTTP::Response`s to a step callback, let that step
return the next batch, repeat until a step returns no request. Three modules:

- `WWW::Chain` (Moo class) — the protocol and the `www_chain` exported builder.
- `WWW::Chain::UA` (`Moo::Role`) — one requirement: `request_chain`.
- `WWW::Chain::UA::LWP` — `extends 'LWP::UserAgent'`, `with 'WWW::Chain::UA'`;
  the only shipped backend.

## The chain protocol

A chain alternates **request batch → step**. `parse_chain(@args)` reads leading
`HTTP::Request` objects into a batch, then the first non-request ends it: a
`CodeRef`, or a `Str` naming a method resolvable via `->can` (subclass mode). Any
leftover after the step, or a batch with zero requests, dies.

State machine, one round per `next_responses` call:

- `next_requests` — the current batch the caller must fulfil (arrayref).
- `next_responses(@responses)` — caller feeds back **exactly** as many
  `HTTP::Response`s as there were requests (else dies), each one an
  `HTTP::Response` (else dies), and not once `done` (else dies). It invokes the
  step with `($chain, @responses)`.
- The step's **return** decides continuation: if the first returned element
  `is_request`, it is `parse_chain`d into the next batch + step and `next_responses`
  returns `0`; otherwise the chain sets `done` and `next_responses` returns the
  `stash`.
- `done` — true when the last step returned no request. `request_count` /
  `result_count` accumulate across rounds.

`stash` is a lazy hashref — the shared accumulator across all steps and the final
result. Steps read/write `$chain->stash->{...}`; nothing else carries data between
rounds.

## Two authoring modes (mixable)

- **Coderef mode** — `www_chain( HTTP::Request->new(...), sub { my ($chain, @resp) = @_; ... } )`.
  `www_chain` accepts a coderef step **only** (a method-name string is rejected
  there). A step returns more `HTTP::Request`s + a coderef to continue, or a
  non-request (typically nothing) to finish.
- **Subclass mode** — `extends 'WWW::Chain'`, define `start_chain` (returns the
  first batch + first step) and named methods as steps returning `..., 'next_method'`.
  `BUILD` calls `start_chain` when no `next_requests` were supplied, so
  `->new` seeds the chain; a subclass with neither is a build-time death.

Both modes may be mixed in one chain (a coderef step may return a method name and
vice versa) because `parse_chain` treats coderef and `->can`-able string alike.

## Running a chain

- **Blocking** — `WWW::Chain::UA::LWP->new->request_chain($chain)` loops
  `next_requests` → `$self->request($_)` → `next_responses(@responses)` until
  `done`; it seeds an empty `cookie_jar` if none is set. `$chain->request_with_lwp`
  is the one-liner shortcut (builds an LWP UA internally).
- **Non-blocking / custom UA** — drive the loop yourself: read `@{$chain->next_requests}`,
  obtain responses however you like, call `$chain->next_responses(@resp)`, repeat
  until `$chain->done`. Any alternative backend `with 'WWW::Chain::UA'` and
  implements `request_chain`.

## Test layout (`t/`, non-recursive `dzil test`)

- `00-load.t` — `all_uses_ok` over the `WWW::Chain` namespace (Test::LoadAllModules).
- `10-base.t` — protocol only, hand-fed `HTTP::Response->new` (no network), asserts
  round count via `done` and the accumulated `stash`.
- `20-lwp.t` / `21-request-with-lwp.t` — end-to-end over a `Test::HTTP::Server`,
  through `request_chain` and `request_with_lwp` respectively.
- `30-methods.t` — subclass mode: `start_chain` + named-method steps.

`10-base.t` and `30-methods.t` prove the protocol without a socket; the LWP tests
prove the backend. A protocol change must keep the hand-fed tests green.
