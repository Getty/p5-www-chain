package WWW::Chain;
# ABSTRACT: A web request chain

our $VERSION ||= '0.000';

=head1 SYNOPSIS

  my $chain = WWW::Chain->new(HTTP::Request->new( GET => 'http://localhost/' ), sub {
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

  # Blocking usage

  my $ua = WWW::Chain::UA::LWP->new;
  $ua->request_chain($chain);

  # ... or non blocking usage example

  unless ($chain->done) {
    my @http_requests = @{$chain->next_requests};
    # ... execute the HTTP::Request objects to get HTTP::Response objects
    $chain->next_responses(@http_responses);
  }

  # Working with the result

  print $chain->stash->{two_calls_finished};

=head1 DESCRIPTION

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Scalar::Util 'blessed';

has stash => (
	isa => HashRef,
	is => 'lazy',
);

sub _build_stash {{}}

has next_requests => (
	isa => ArrayRef,
	is => 'rwp',
	clearer => 1,
	required => 1,
);

has next_coderef => (
	isa => CodeRef,
	is => 'rwp',
	clearer => 1,
);

has done => (
	isa => Bool,
	is => 'rwp',
	default => sub { 0 },
);

has request_count => (
	isa => Num,
	is => 'rwp',
	default => sub { 0 },
);

has result_count => (
	isa => Num,
	is => 'rwp',
	default => sub { 0 },
);

sub BUILDARGS {
	my $self = shift;
	my ( $next_requests, $next_coderef, @args ) = $self->parse_chain(@_);
	return {
		next_requests => $next_requests,
		next_coderef => $next_coderef,
		request_count => scalar @{$next_requests},
		@args,
	};
}

sub parse_chain {
	my ( $self, @args ) = @_;
	my $coderef;
	my @requests;
	while (@args) {
		my $arg = shift @args;
		if ( blessed($arg) && $arg->isa('HTTP::Request') ) {
			push @requests, $arg;
		} elsif (ref $arg eq 'CODE') {
			$coderef = $arg;
			last;
		} else {
			die __PACKAGE__."->parse_chain got unparseable element".(defined $arg ? " ".$arg : "" );
		}
	}
	die __PACKAGE__."->parse_chain found no HTTP::Request objects" unless @requests;
	return [@requests], $coderef, @args;
}

sub next_responses {
	my ( $self, @responses ) = @_;
	die __PACKAGE__."->next_responses can't be called on chain which is done." if $self->done;
	my $amount = scalar @{$self->next_requests};
	die __PACKAGE__."->next_responses would need ".$amount." HTTP::Response objects to proceed"
		unless scalar @responses == $amount;
	die __PACKAGE__."->next_responses only takes HTTP::Response objects"
		if grep { !$_->isa('HTTP::Response') } @responses;
	$self->clear_next_requests;
	my @result = $self->next_coderef->($self, @responses);
	$self->clear_next_coderef;
	$self->_set_result_count($self->result_count + 1);
	if ( defined $result[0] && blessed($result[0]) && $result[0]->isa('HTTP::Request') ) {
		my ( $next_requests, $next_coderef, @args ) = $self->parse_chain(@result);
		die __PACKAGE__."->next_responses can't parse the result, more arguments after CodeRef" if @args;
		$self->_set_next_requests($next_requests);
		$self->_set_next_coderef($next_coderef);
		$self->_set_request_count($self->request_count + scalar @{$next_requests});
		return 0;
	}
	$self->_set_done(1);
	return 1;
}

1;
