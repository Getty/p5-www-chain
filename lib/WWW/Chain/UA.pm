package WWW::Chain::UA;
# ABSTRACT: Role for classes which have a request_chain function for a WWW::Chain object
our $VERSION = '0.102';
use Moo::Role;

requires qw( request_chain );

1;