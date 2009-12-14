#!/usr/bin/perl -w
use strict;
use Encode;

if (!defined($ARGV[0])) {
    print "Usage: getip.pl [ip address]\n";
    exit 1;
}

my $curlcmd = "curl --connect-timeout 5 -s -S";
my $response 
    = `$curlcmd -d "ip=$ARGV[0]&action=2\n---" http://www.ip138.com/ips8.asp`;

exit 2 if ($?);

$response = encode("utf8", decode("gbk", $response));

if ($response =~ /<li>本站主数据：([^<]+)/) {
    printf "%s: %s\n", $ARGV[0], $1;
    exit 0;
}
else {
    exit 3;
}

