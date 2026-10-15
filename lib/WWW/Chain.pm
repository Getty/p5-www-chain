package WWW::Chain;
# ABSTRACT: A web request chain
our $VERSION = '0.102';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Safe::Isa;
use WWW::Chain::UA::LWP;
use Exporter 'import';

our @EXPORT = qw( www_chain );

has stash => (
  isa => HashRef,
  is => 'lazy',
);
sub _build_stash {{}}

has next_requests => (
  isa => ArrayRef,
  is => 'rwp',
  clearer => 1,
);

has next_step => (
  isa => AnyOf[Str, CodeRef],
  is => 'rwp',
  clearer => 1,
);

has done => (
  isa => Bool,
  is => 'rwp',
  lazy => 1,
  default => sub { 0 },
);

has request_count => (
  isa => Num,
  is => 'rwp',
  lazy => 1,
  default => sub { 0 },
);

has result_count => (
  isa => Num,
  is => 'rwp',
  lazy => 1,
  default => sub { 0 },
);

sub www_chain {
  my ( @args ) = @_;
  my ( $next_requests, $next_step, @others ) = __PACKAGE__->parse_chain(@args);
  die __PACKAGE__." can only use coderef as next step" unless !$next_step or ref $next_step eq 'CODE';
  return WWW::Chain->new(
    next_requests => $next_requests,
    next_step => $next_step,
    request_count => scalar @{$next_requests},
    @others,
  );
}

sub request_with_lwp {
  my ( $self ) = @_;
  return WWW::Chain::UA::LWP->new->request_chain($self);
}

sub is_response { $_[1]->$_isa('HTTP::Response') }
sub is_request { $_[1]->$_isa('HTTP::Request') }

sub parse_chain {
  my ( $self, @args ) = @_;
  my $step;
  my @requests;
  while (@args) {
    my $arg = shift @args;
    if ( $self->is_request($arg) ) {
      push @requests, $arg;
    } elsif (ref $arg eq '') {
      die "".(ref $self)."->parse_chain '".$arg."' is not a known function" unless $self->can($arg);
      $step = $arg;
      last;
    } elsif (ref $arg eq 'CODE') {
      $step = $arg;
      last;
    } else {
      die __PACKAGE__."->parse_chain got unparseable element".(defined $arg ? " ".$arg : "" );
    }
  }
  die __PACKAGE__."->parse_chain found no HTTP::Request objects" unless @requests;
  return \@requests, $step, @args;
}

sub next_responses {
  my ( $self, @responses ) = @_;
  die "".(ref $self)."->next_responses can't be called on chain which is done." if $self->done;
  my $amount = scalar @{$self->next_requests};
  die "".(ref $self)."->next_responses would need ".$amount." HTTP::Response objects to proceed"
    unless scalar @responses == $amount;
  die "".(ref $self)."->next_responses only takes HTTP::Response objects"
    if grep { !$self->is_response($_) } @responses;
  $self->clear_next_requests;
  my @result = $self->${\$self->next_step}(@responses);
  $self->clear_next_step;
  $self->_set_result_count($self->result_count + 1);
  # If the first result is a request again, then we need to parse_chain again.
  if ( $self->is_request($result[0]) ) {
    my ( $next_requests, $next_step, @others ) = $self->parse_chain(@result);
    die "".(ref $self)."->next_responses can't parse the result, more arguments after next step" if @others;
    $self->_set_next_requests($next_requests);
    $self->_set_next_step($next_step);
    $self->_set_request_count($self->request_count + scalar @{$next_requests});
    return 0;
  }
  $self->_set_done(1);
  return $self->stash;
}

sub BUILD {
  my ( $self ) = @_;
  unless ($self->next_requests) {    
    die "".(ref $self)." has no start_chain function and no requests supplied on build" unless $self->can('start_chain');
    my ( $next_requests, $next_step, @others ) = $self->parse_chain($self->start_chain);
    die "".(ref $self)." parse_chain can't parse the start_chain return, more arguments after next step" if scalar @others > 0;
    die "".(ref $self)." has no requests from start_chain" unless scalar @{$next_requests} > 0;
    $self->_set_next_step($next_step) if $next_step;
    $self->_set_next_requests($next_requests);
    $self->_set_request_count(scalar @{$next_requests});
  }
}

1;


=head1 SYNOPSIS

  # Coderef usage

  use WWW::Chain; # exports www_chain

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

  # Method usage (can be mixed with Coderef)

  {
    package TestWWWChainMethods;
    use Moo;
    extends 'WWW::Chain';

    has path_part => (
      is => 'ro',
      required => 1,
    );

    # Function used to determine first requests on class, will be added to BUILDARGS
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
  }

  my $chain = TestWWWChainMethods->new( path_part => 'wwwchain' );

  # Blocking usage:

  my $ua = WWW::Chain::UA::LWP->new;
  $ua->request_chain($chain);

  # ... or non blocking usage example:

  my @http_requests = @{$chain->next_requests};
  # ... do something with the HTTP::Request objects to get HTTP::Response objects
  $chain->next_responses(@http_responses);
  # repeat those till $chain->done

  # Working with the result

  print $chain->stash->{two_calls_finished};

=head1 DESCRIPTION

A L<WWW::Chain> object drives a multi-step HTTP conversation: it fires a batch
of L<HTTP::Request> objects, hands the resulting L<HTTP::Response> objects to a
step callback, and repeats with whatever that step returns, until a step
returns no request. A whole sequence of dependent requests — a login and the
pages behind it, a redirect, a paginated fetch — becomes one object that a user
agent (or your own event loop) runs to completion.

=head2 The chain protocol

A chain alternates request batch and step. C<parse_chain> reads the leading
L<HTTP::Request> objects into a batch; the first non-request element ends the
batch and is the step for it — either a C<CodeRef>, or a C<Str> naming a method
resolvable via C<< ->can >> (subclass mode). A batch with no request, or
anything left over after the step, is fatal.

C<next_requests> is the current batch the caller must fulfil, as an arrayref.
C<next_responses(@responses)> feeds the results back and enforces the contract:
it must be handed B<exactly> as many L<HTTP::Response> objects as there were
requests (otherwise it dies), each one an L<HTTP::Response> (otherwise it dies),
and never once the chain is C<done> (otherwise it dies). It then invokes the
step as C<< $step->($chain, @responses) >>.

The step's return value decides continuation. If its first element
C<is_request>, the return is C<parse_chain>d into the next batch plus step and
C<next_responses> returns C<0>; otherwise the chain sets C<done> and
C<next_responses> returns the C<stash>. C<done> is true once the last step
returned no request; C<request_count> and C<result_count> accumulate across all
rounds.

=head2 The stash

C<stash> is a lazy hashref: the shared accumulator across every step and the
final result. Steps read and write C<< $chain->stash->{...} >>; nothing else
carries data from one round to the next.

=head2 Authoring modes

The two modes may be mixed within one chain, because C<parse_chain> treats a
coderef step and a C<< ->can >>-able method name alike.

In B<coderef mode> you call the exported C<www_chain> builder with one or more
L<HTTP::Request> objects followed by a C<sub>; a step returns more requests plus
a coderef to continue, or a non-request (typically nothing) to finish.
C<www_chain> accepts a coderef step B<only> — a method-name string is rejected
there.

In B<subclass mode> you C<extends 'WWW::Chain'>, define C<start_chain> to return
the first batch and first step, and add named methods as steps that return
C<< ..., 'next_method' >>. C<BUILD> calls C<start_chain> when no C<next_requests>
were supplied to the constructor, so C<< ->new >> seeds the chain; a subclass
with neither is a build-time death.

=head2 Running a chain

Run it blocking through the shipped L<WWW::Chain::UA::LWP> backend, or drive
C<next_requests> / C<next_responses> by hand for non-blocking or custom-backend
use — see L<WWW::Chain::UA>.

=cut