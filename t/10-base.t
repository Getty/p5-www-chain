#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use WWW::Chain;
use HTTP::Request;
use HTTP::Response;

my $chain = www_chain(HTTP::Request->new( GET => 'http://www.perl.org/' ), sub {
	isa_ok($_[0],'WWW::Chain');
	$_[0]->stash->{a} = 1;
	isa_ok($_[1],'HTTP::Response');
	return HTTP::Request->new( GET => 'http://www.perl.org/' ), sub {
		isa_ok($_[0],'WWW::Chain');
		$_[0]->stash->{b} = 2;
		isa_ok($_[1],'HTTP::Response');
		return;
	};
});

isa_ok($chain,'WWW::Chain');

$chain->next_responses(HTTP::Response->new);
ok(!$chain->done,'Chain is not done');

$chain->next_responses(HTTP::Response->new);
ok($chain->done,'Chain is done');

is_deeply($chain->stash,{ a => 1, b => 2 },'Stash is proper');

my $no_step = HTTP::Request->new( GET => "http://www.perl.org/" );
like(do { eval { www_chain($no_step) }; $@ },qr/found no next step/,"www_chain without a step is rejected clearly");

my $stepless = www_chain($no_step, sub { return HTTP::Request->new( GET => "http://www.perl.org/" ) });
like(do { eval { $stepless->next_responses(HTTP::Response->new) }; $@ },qr/found no next step/,"a step returning only requests is rejected clearly");

done_testing;
