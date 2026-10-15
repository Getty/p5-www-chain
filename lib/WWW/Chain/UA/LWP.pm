package WWW::Chain::UA::LWP;
# ABSTRACT: Using LWP::UserAgent to execute WWW::Chain chains
our $VERSION = '0.102';
use Moo;
extends 'LWP::UserAgent';

with qw( WWW::Chain::UA );

use HTTP::Cookies;
use Scalar::Util 'blessed';
use Safe::Isa;

sub request_chain {
  my ( $self, $chain ) = @_;
  die __PACKAGE__."->request_chain needs a WWW::Chain object as parameter"
    unless ( blessed($chain) && $chain->$_isa('WWW::Chain') );
  $self->cookie_jar({}) unless $self->cookie_jar;
  while (!$chain->done) {
    my @responses;
    for (@{$chain->next_requests}) {
      my $response = $self->request($_);
      push @responses, $response;
    }
    $chain->next_responses(@responses);
  }
  return $chain;
}

1;

=method request_chain

  $ua->request_chain($chain);

The blocking implementation of the L<WWW::Chain::UA> requirement: it seeds an
empty C<cookie_jar> if none is set, then loops the chain — issuing each request
in C<< @{$chain->next_requests} >> through C<< $self->request >> and feeding the
responses back with C<< $chain->next_responses >> — until C<< $chain->done >>,
and returns the chain. C<< $chain->request_with_lwp >> is the one-line shortcut
that builds an agent internally.

=cut