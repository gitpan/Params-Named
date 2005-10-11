package Params::Named;

$VERSION = '1.0.0';

## Might as well be standardized.
require Exporter;
@ISA     = 'Exporter';
@EXPORT  = 'MAPARGS';

use strict;

use Carp       qw/croak carp/;
use PadWalker  'peek_sub';
use List::Util 'first';

## Map named arguments to variables of those names.
sub MAPARGS {
  ## The arguments of the caller.
  my %args = do { package DB; () = caller 1; @DB::args };
  ## The lexical values of the caller.
  my $vals = peek_sub \&{(caller 1)[3]};
  ## Map the lexicals of the caller to the caller's arguments.
  my %vmap = map { $_ => $args{substr($_, 1)} }
             grep exists $args{substr($_, 1)}, keys %$vals;
  ## Map arguments to MAPARGS to the appropriate lexicals.
  my %pmap = map {
    my $orig_arg = !ref($_)?\$_:$_;
    my $ref_name = first { $orig_arg == $vals->{$_} } keys %$vals;
    $ref_name => $orig_arg;
  } @_;

  carp sprintf "No parameters mapped for '%s' at line no. '%s'",
               (caller 1)[3,2]
    if !keys %vmap;

  ## Now assign the caller's arguments to the caller's lexicals.
  for(keys %vmap) {
    ## Param is a SCALAR and the value is SCALAR or REF.
    if( ref $pmap{$_} eq 'SCALAR'
    && ((ref $vmap{$_} || ref \$vmap{$_}) eq 'SCALAR') || (ref $vmap{$_} eq 'REF')) {
      ${ $pmap{$_} } = $vmap{$_};
      next;
    }
    ## Param is ARRAY and value is ARRAY
    if(ref $pmap{$_} eq 'ARRAY' && ref $vmap{$_} eq 'ARRAY')  {
      @{ $pmap{$_} } = @{ $vmap{$_} };
      next;
    }
    ## Param is HASH and value is HASH
    if(ref $pmap{$_} eq 'HASH' && ref $vmap{$_} eq 'HASH')   {
      %{ $pmap{$_} } = %{ $vmap{$_} };
      next;
    }
    croak
      sprintf "The parameter '%s' doesn't match argument type '%s'",
              $_, ( ref $vmap{$_} || ref \$vmap{$_} );
  }

  return \%vmap;
}

1;

=pod

=head1 NAME

Params::Named - Map incoming arguments to parameters of the same name.

=head1 SYNOPSIS

  use Params::Named;
  use IO::All;

  sub storeurl {
    my $self = shift;
    MAPARGS \my($src, $dest);
    return io($src) > io($dest);
  }
  $obj->storeurl(src => $url, dest => $fh);

=head1 DESCRIPTION

This module does just one thing - it maps named arguments to a subroutine's
lexical parameter variables or, more specifically, any lexical variables
passed into C<MAPARGS>. Named parameters are exactly the same as a flattened
hash in that they provide a list of C<< key => value >> pairs. So for each
key that matches a lexical variable passed to C<MAPARGS> the corresponding
value will be mapped to that variable. Here is a short example to demonstrate
C<MAPARGS> in action:

  use Params::Named;
  sub mapittome {
    MAPARGS \my($this, @that, %other);
    print "This is:   '$this'\n";
    print "That is:   ", join(', ', @that), "\n";
    print "The other: ", join(', ',
                              map "$_ => $other{$_}", keys %other), "\n";
  }

  mapittome this  => 'a simple string',
            that  => [qw/a list of items/],
            other => {qw/a hash containing pairs/};
  ## Or if you've got a hash.
  my %args = (
    this  => 'using a hash',
    that  => [qw/is very cool/],
    other => {qw/is it not cool?/},
  );
  mapittome %args;

The example above illustrates the mapping of C<mapittome>'s arguments to
its parameters. It will work on scalars, arrays and hashes, the 3 types
of lexical values.

=head1 FUNCTIONS

=over 4

=item MAPARGS

Given a list of variables map those variables to named arguments from
the caller's argument stack (e.g C<@_>). Taking advantage of one of
Perl's more under-utilized features, passing in a list of references
as created by applying the reference operator to a list will allow the
mapping of compound variables (without the reference lexically declared
arrays and hashes flatten to an empty list). Argument types must match
their corresponding parameter types e.g C<< foo => \@things >> should map
to a parameter declared as an array e.g C<MAPARGS \my(@foo)>.

=back

=head1 EXPORTS

C<MAPARGS>

=head1 DIAGNOSTICS

=over 4

=item C<No parameters mapped for '%s' at line no. '%s'>

This warning is issued because none of the arguments matched any of the
parameters, so no mapping is performed.

=item C<The parameter '%s' doesn't match argument type '%s'>

A given parameter doesn't match it's corresponding argument's type e.g

  sub it'llbreak { MAPARGS \my($foo, @bar); ... }
  ## This will croak() because @bar's argument isn't an array reference.
  it'llbreak foo => 'this', bar => 'that';

So either the parameter or the argument needs to be updated to reflect
the desired behaviour.

=back
  
=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 COPYRIGHT

Copyright (c) 2005, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.

=cut
