use strict;
use warnings;

use Test::More tests => 13;

use Params::Named;

{
  sub testme {
    MAPARGS my($foo, $bar, $baz);
    return $foo, $bar, $baz;
  }

  my($a,$b,$c) = eval { testme qw/ foo this bar that baz theother / };
  ok !$@, 'A basic MAPARGS call.';
  ok eq_array([$a,$b,$c], [qw/this that theother/]), 'Args match with values.';

  my %hash   = qw/ foo x bar y baz z /;
  ($a,$b,$c) = testme %hash;
  ok eq_array([$a,$b,$c], ['x' .. 'z']), 'A flattened hash works as expected.';
}

{
  sub testhis {
    MAPARGS \my($x, @y, %z);
    return $x, \@y, \%z;
  }

  my($x,$y,$z) = ('a string',[qw/an array/],{qw/a hash/});
  my($a,$b,$c) = eval { testhis x => $x, y => $y, z => $z };
  ok !$@, 'Mapped different data types ok.';
  is       $a, $x, 'The string matched normally.';
  ok eq_array($b, $y), 'The array mapped and matches correctly.';
  ok eq_hash( $c, $z), 'The hash mapped and matches correctly.';

  ($a) = eval { testhis x => \\'thingie' };
  ok !$@, 'Mapped what is a REF in 5.8 without a problem.';
  is $$$a, 'thingie', 'The string in REF is as expected.';

  local $@;
  eval { testhis y => {} };
  ok $@, 'Giving an incorrect type dies expectedly.';
  like $@, qr/\@y.*?HASH/, 'The error message looks about right.';
}

{
  ## I could use Test::Warn, but for ONE test? Don't think so.
  local $SIG{__WARN__} = sub {
    like $_[0],
         qr/No parameters mapped for 'main::nomatch' at line no\. '\d+'/,
         'Got the expected warning when no parameters matched.';
  };
  sub nomatch {
    MAPARGS \my($these, $are, @args);
    return $these, $are, \@args;
  }

  eval { nomatch qw/ none of this list will match / };
  ok !$@, "Not passing in any expected params doesn't die.";
}
