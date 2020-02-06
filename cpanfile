
requires 'Moo', '1.000004';
requires 'MooX::Types::MooseLike::Base', '0.16';
requires 'LWP', '6.04';
requires 'Safe::Isa', '1.000002';

on test => sub {
  requires 'Test::More', '0.98';
  requires 'HTTP::Request', '0';
  requires 'HTTP::Response', '0';
  requires 'Test::LoadAllModules', '0.021';
  requires 'Test::HTTP::Server', '0.03';
};
