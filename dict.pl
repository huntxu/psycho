#!/usr/bin/perl -w
use strict;
use Pod::Escapes qw(e2char);
use Encode;

if ( !defined( $ARGV[0] ) ) {
    print "Usage: dict.pl word\n";
    print "       dict.pl [word]\n";
    exit 1;
}
$_ = join "%20", @ARGV;
s/ /%20/g;

my $curlcmd =
"curl -s -S -A \"Opera/10.00 (X11; Linux i686 ; U; en) Presto/2.2.0\" --connect-timeout 5";
my $response = `$curlcmd http://dict.cn/compact.php?q=$_`;

exit 2 if ($?);

$response = encode( "utf8", decode( "gbk", $response ) );

if ( $response =~
m[<h1>(?<word>.+)</h1>(.*?<span class="pronounce">(?<pronounce>.+)</span>)?.*?<strong>(?<meaning>.+)</strong>]s
  )
{
    my %content = %+;

    if ( defined( $content{pronounce} ) ) {
        my $sub;
        foreach ( $content{pronounce} =~ /&#(.*?);/g ) {
            $sub = e2char($_);
            $content{pronounce} =~ s/&#$_;/$sub/g;
        }
        $content{pronounce} = encode( "utf8", $content{pronounce} );
    }
    else {
        $content{pronounce} = "";
    }

    $content{meaning} =~ s[<br />][|| ]g;

    printf "%s - %s - %s\n",
      $content{word},
      $content{pronounce},
      $content{meaning};
}
else {
    my ( $sound, $word ) =
        ( $ARGV[0] =~ /\[(.+)\]/ )
      ? ( " sound", $1 )
      : ( "", $ARGV[0] );
    my $msg;

    @_ = ( $response =~ m[<li><a.+>(.+)</a></li>]g );
    if ( @_ == 0 ) {
        $msg = "No word$sound similar with \"$word\" found";
    }
    else {
        foreach (@_) {
            $msg .= " $_";
        }
        $msg = "Words$sound similar with \"$word\":$msg";
    }
    print "$msg\n";
}
