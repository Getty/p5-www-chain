package WWW::Chain::UA;
# ABSTRACT: Role for classes which have a request_chain function for a WWW::Chain object
our $VERSION = '0.102';
use Moo::Role;

requires qw( request_chain );

1;

=head1 DESCRIPTION

C<WWW::Chain::UA> is the L<Moo::Role> a user agent consumes to run a
L<WWW::Chain> to completion. It has a single requirement, C<request_chain>;
C<< with 'WWW::Chain::UA' >> fails at composition time if the consumer does not
provide it. The only backend shipped in this distribution is
L<WWW::Chain::UA::LWP>, a blocking agent built on L<LWP::UserAgent>.

=method request_chain

  $ua->request_chain($chain);

Runs the given L<WWW::Chain> to completion and returns it. An implementation
loops over the chain protocol: read the current batch from
C<< @{$chain->next_requests} >>, obtain an L<HTTP::Response> for each request
however the backend sees fit, feed them back with
C<< $chain->next_responses(@responses) >>, and repeat until C<< $chain->done >>
is true.

=head1 NON-BLOCKING USAGE

You do not need a C<WWW::Chain::UA> to run a chain at all: to drive one yourself
— for a non-blocking event loop, or any transport you like — read the current
batch from C<< @{$chain->next_requests} >>, obtain the responses however you
wish, hand them to C<< $chain->next_responses(@responses) >>, and repeat until
C<< $chain->done >>:

  until ($chain->done) {
    my @responses = map { get_response_somehow($_) } @{$chain->next_requests};
    $chain->next_responses(@responses);
  }

=head1 WRITING A BACKEND

An alternative user agent composes this role and implements C<request_chain>:

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

=cut