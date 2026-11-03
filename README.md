# WWW::Chain

A web request chain: fire a batch of HTTP requests, hand the responses to a step, repeat with whatever the step returns.

## Synopsis

```perl
use WWW::Chain;    # exports www_chain
use HTTP::Request;

my $chain = www_chain(HTTP::Request->new( GET => 'http://localhost/' ), sub {
  my ( $chain, $response ) = @_;
  $chain->stash->{first_request} = 'done';
  return
    HTTP::Request->new( GET => 'http://localhost/' ),
    HTTP::Request->new( GET => 'http://other.localhost/' ),
    sub {
      my ( $chain, $first_response, $second_response ) = @_;
      $chain->stash->{two_calls_finished} = 'done';
      return;
    };
});

$chain->request_with_lwp;
print $chain->stash->{two_calls_finished};
```

## Description

A `WWW::Chain` object drives a multi-step HTTP conversation: it fires a batch of
`HTTP::Request` objects, hands the resulting `HTTP::Response` objects to a step
callback, and repeats with whatever that step returns, until a step returns no
request. A login and the pages behind it, a redirect or a paginated fetch becomes
one object that a user agent, or your own event loop, runs to completion.

A step is called as `$step->($chain, @responses)`. When its first return value is
an `HTTP::Request`, the return is parsed into the next batch plus the next step;
otherwise the chain is `done` and `next_responses` returns the `stash`, the hashref
that carries data from step to step and holds the final result. A chain runs at
most `max_steps` steps (100 by default).

## Coderef mode

`www_chain` takes one or more `HTTP::Request` objects followed by a coderef step:

```perl
my $chain = www_chain(
  HTTP::Request->new( GET => 'http://localhost/' ),
  sub {
    my ( $chain, $response ) = @_;
    $chain->stash->{status} = $response->code;
    return;
  },
);
```

## Subclass mode

Extend `WWW::Chain`, return the first batch and the first step from `start_chain`,
and name the following steps as methods:

```perl
package MyChain;
use Moo;
extends 'WWW::Chain';

has path_part => ( is => 'ro', required => 1 );

sub start_chain {
  return HTTP::Request->new( GET => 'https://conflict.industries/'.$_[0]->path_part ), 'first_response';
}

sub first_response {
  $_[0]->stash->{a} = 1;
  return HTTP::Request->new( GET => 'https://conflict.industries/'.$_[0]->path_part ), 'second_response';
}

sub second_response {
  $_[0]->stash->{b} = 2;
  return;
}

my $chain = MyChain->new( path_part => 'wwwchain' );
```

## Running a chain

Blocking, through `WWW::Chain::UA::LWP` (an `LWP::UserAgent` with a 30 second
default timeout and an empty cookie jar if none is set):

```perl
WWW::Chain::UA::LWP->new->request_chain($chain);
# or
$chain->request_with_lwp;
```

Non-blocking, or with any transport you like, drive the chain by hand:

```perl
until ($chain->done) {
  my @responses = map { get_response_somehow($_) } @{$chain->next_requests};
  $chain->next_responses(@responses);
}
```

`next_responses` takes exactly as many `HTTP::Response` objects as there were
requests, and not once the chain is `done`.

## Writing a backend

A user agent consumes the `WWW::Chain::UA` role and implements `request_chain`:

```perl
package WWW::Chain::UA::MyBackend;
use Moo;
with 'WWW::Chain::UA';

sub request_chain {
  my ( $self, $chain ) = @_;
  until ($chain->done) {
    my @responses = map { $self->my_request($_) } @{$chain->next_requests};
    $chain->next_responses(@responses);
  }
  return $chain;
}
```

## Installation

```bash
cpanm WWW::Chain
```

## License

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de>.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
