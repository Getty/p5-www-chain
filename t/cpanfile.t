#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use FindBin;
use Test::More;

my $cpanfile = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'cpanfile' );

plan skip_all => 'cpanfile is not part of the distribution' unless -f $cpanfile;

open my $fh, '<', $cpanfile or die "cannot read $cpanfile: $!";
my %requires;
while ( my $line = <$fh> ) {
  next unless $line =~ /^\s*requires\s+'([^']+)'/;
  $requires{ $1 } = 1;
}
close $fh;

# The chain fetches every url the caller names, so the transport for https has
# to be part of the distribution: without LWP::Protocol::https a fresh install
# answers 501 on the first https request. The other modules are the ones the
# code under lib/ uses.
for my $module (qw(HTTP::Cookies LWP LWP::Protocol::https Moo MooX::Types::MooseLike::Base Safe::Isa)) {
  ok( $requires{$module}, "$module is a declared prerequisite" );
}

done_testing;
