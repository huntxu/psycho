#!/usr/bin/perl -w
use strict;
use Encode;

sub to_utf8 {
    my ( $msg, $charset ) = @_;
    $msg = encode( "utf8", decode( $charset, $msg ) );
    return $msg;
}

unless ( defined( $ARGV[0] ) ) {
    print "Usage: geturltitle.pl URL\n";
    exit 1;
}

my $curlcmd =
"curl -s -S -A \"Opera/10.00 (X11; Linux i686 ; U; en) Presto/2.2.0\" --connect-timeout 6 --max-filesize 102400 --location-trusted -i --max-redirs 3";
my $response = `$curlcmd $ARGV[0]`;

exit 2 if ($?);

if ( $response =~ m|Content-Type.*charset=([\w\-]*)|i ) {
    $_ = $1;
    unless (/(?:utf-8)|(?:iso-8859-1)/i) {
        $response = to_utf8( $response, $_ );
    }
}
if ( $response =~ m|<title>(.*?)</title>|si ) {
    $_ = `echo "$1" | ascii2uni -a Y -q`;
    exit 2 if ($?);
    s/\n/ /g;
    print $_. "\n";
}
else {
    exit 2;
}
