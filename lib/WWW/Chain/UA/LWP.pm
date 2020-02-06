package WWW::Chain::UA::LWP;
# ABSTRACT: Using LWP::UserAgent to execute WWW::Chain chains

use Moo;
extends 'LWP::UserAgent';

use HTTP::Cookies;

with qw( WWW::Chain::UA );

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