package WWW::Chain::UA::LWP;

use Moo;
extends 'LWP::UserAgent';

with qw( WWW::Chain::UA );

use Scalar::Util 'blessed';

sub request_chain {
	my ( $self, $chain ) = @_;
	die __PACKAGE__."->request_chain needs a WWW::Chain object as parameter"
		unless ( blessed($chain) && $chain->isa('WWW::Chain') );
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