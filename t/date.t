#!perl

use strict;
use warnings;

use Test::More tests => 152;
use HTTP::Date;

# test str2time for supported dates.  Test cases with 2 digit year
# will probably break in year 2044.
my (@tests) = (
    'Thu Feb  3 00:00:00 GMT 1994',    # ctime format
    'Thu Feb  3 00:00:00 1994',        # same as ctime, except no TZ

    'Thu, 03 Feb 1994 00:00:00 GMT',         # proposed new HTTP format
    'Thursday, 03-Feb-94 00:00:00 GMT',      # old rfc850 HTTP format
    'Thursday, 03-Feb-1994 00:00:00 GMT',    # broken rfc850 HTTP format

    '03/Feb/1994:00:00:00 0000',             # common logfile format
    '03/Feb/1994:01:00:00 +0100',            # common logfile format
    '02/Feb/1994:23:00:00 -0100',            # common logfile format

    '03 Feb 1994 00:00:00 GMT',    # HTTP format (no weekday)
    '03-Feb-94 00:00:00 GMT',      # old rfc850 (no weekday)
    '03-Feb-1994 00:00:00 GMT',    # broken rfc850 (no weekday)
    '03-Feb-1994 00:00 GMT',       # broken rfc850 (no weekday, no seconds)
    '03-Feb-1994 00:00',           # VMS dir listing format

    '03-Feb-94',      # old rfc850 HTTP format    (no weekday, no time)
    '03-Feb-1994',    # broken rfc850 HTTP format (no weekday, no time)
    '03 Feb 1994',    # proposed new HTTP format  (no weekday, no time)
    '03/Feb/1994',    # common logfile format     (no time, no offset)

    #'Feb  3 00:00',     # Unix 'ls -l' format (can't really test it here)
    'Feb  3 1994',    # Unix 'ls -l' format

    "02-03-94  12:00AM",    # Windows 'dir' format
    "02-03-1994  12:00AM",  # Windows 'dir' format with four-digit year

    # ISO 8601 formats
    '1994-02-03 00:00:00 +0000',
    '1994-02-03',
    '19940203',
    '1994-02-03T00:00:00+0000',
    '1994-02-02T23:00:00-0100',
    '1994-02-02T23:00:00-01:00',
    '1994-02-03T00:00:00 Z',
    '19940203T000000Z',
    '199402030000',

    # A few tests with extra space at various places
    '  03/Feb/1994      ',
    '  03   Feb   1994  0:00  ',

    # Tests a commonly used (faulty?) date format of php cms systems
    'Thu, 03 Feb 1994 00:00:00 +0000 GMT',

    # Test with Time::Zone
    '03 Feb 1994 02:00:00 CEST',
);

my $time = 760233600;    # assume broken POSIX counting of seconds
for (@tests) {
    my $t;
    if (/GMT/i) {
        $t = str2time($_);
    }
    else {
        $t = str2time( $_, "GMT" );
    }
    my $t2 = str2time( lc($_), "GMT" );
    my $t3 = str2time( uc($_), "GMT" );

    note "\n'$_'";

    is( $t,  $time );
    is( $t2, $time );
    is( $t3, $time );
}

# test time2str
is( time2str($time), 'Thu, 03 Feb 1994 00:00:00 GMT' );

# test the 'ls -l' format with missing year$
# round to nearest minute 3 days ago.
my $passed = 0;

# Put in a hack to make the test pass due to daylight savings time affecting
# the result
for my $day ( 3 .. 4 ) {
    $time = int( ( time - $day * 24 * 60 * 60 ) / 60 ) * 60;
    my ( $min, $hr, $mday, $mon ) = ( localtime $time )[ 1, 2, 3, 4 ];
    $mon = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
    my $str = sprintf( "$mon %02d %02d:%02d", $mday, $hr, $min );
    my $t   = str2time($str);
    if ( $t == $time ) {
        $passed = 1;
        last;
    }
}
ok($passed);

# try some garbage.
for (
    undef, '', 'Garbage',
    'Mandag 16. September 1996',
    '12 Arp 2003',

    #     'Thu Feb  3 00:00:00 CET 1994',
    #     'Thu, 03 Feb 1994 00:00:00 CET',
    #     'Wednesday, 31-Dec-69 23:59:59 GMT',

    '1980-00-01',
    '1980-13-01',
    '1980-01-00',
    '1980-01-32',
    '1980-01-01 25:00:00',
    '1980-01-01 00:61:00',
    '1980-01-01 00:00:61',

    # Negative time
    '1880-01-01',
    'Thu, 01 Jan 1880 00:00:00 GMT',
    '01/Jan/1880:00:00:00 0000',

    # Bad timezone string
    '01 Jan 1994 02:00:00 BAD',
) {
    my $bad = 0;
    eval {
        if ( defined str2time $_) {
            print "str2time($_) is not undefined\n";
            $bad++;
        }
    };
    note defined($_) ? "\n'$_'" : "undef";
    ok( !$@ );
    ok( !$bad );
}

note "Testing AM/PM gruff...";

# Test the str2iso routines
use HTTP::Date qw(time2iso time2isoz);

note "Testing time2iso functions";

my $t = time2iso( str2time("11-12-96  0:00AM") );
is( $t, "1996-11-12 00:00:00" );

$t = time2iso( str2time("11-12-96 12:00AM") );
is( $t, "1996-11-12 00:00:00" );

$t = time2iso( str2time("11-12-96  0:00PM") );
is( $t, "1996-11-12 12:00:00" );

$t = time2iso( str2time("11-12-96 12:00PM") );
is( $t, "1996-11-12 12:00:00" );

$t = time2iso( str2time("11-12-96  1:05AM") );
is( $t, "1996-11-12 01:05:00" );

$t = time2iso( str2time("11-12-96 12:05AM") );
is( $t, "1996-11-12 00:05:00" );

$t = time2iso( str2time("11-12-96  1:05PM") );
is( $t, "1996-11-12 13:05:00" );

$t = time2iso( str2time("11-12-96 12:05PM") );
is( $t, "1996-11-12 12:05:00" );

$t = time2iso( str2time("11-12-01 12:00PM") );
is( $t, "2001-11-12 12:00:00" );

$t = time2iso( str2time("11-12-1996 12:00AM") );
is( $t, "1996-11-12 00:00:00" );

$t = time2iso( str2time("11-12-2022 12:00AM") );
is( $t, "2022-11-12 00:00:00" );

$t = str2time("2000-01-01 00:00:01.234");
note "FRAC $t = ", time2iso($t);
cmp_ok( abs( ( $t - int($t) ) - 0.234 ), '<', 0.000001 );

$a = time2iso;
$b = time2iso(500000);
note "LOCAL $a  $b";
my $az = time2isoz;
my $bz = time2isoz(500000);
note "GMT   $az $bz";

for ( $a,  $b )  { like($_, qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$/); }
for ( $az, $bz ) { like($_, qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\dZ$/); }

# Test the parse_date interface
use HTTP::Date qw(parse_date);

my @d = parse_date("Jan 1 2001");
is_deeply( \@d, [2001, 1, 1, 0, 0, 0, undef] );

# This test will break around year 2070
is( parse_date("03-Feb-20"), "2020-02-03 00:00:00" );

# This test will break around year 2048
is( parse_date("03-Feb-98"), "1998-02-03 00:00:00" );

note "HTTP::Date $HTTP::Date::VERSION";
