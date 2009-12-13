#!/usr/bin/perl -w
use strict;

if (!defined($ARGV[0])) {
    print "Usage: weather.pl cityname\n";
    exit 1;
}

my $curlcmd = "curl --connect-timeout 5 -s -S";
my $response 
    = `$curlcmd -d cityinfo=$ARGV[0] http://search.weather.com.cn/static/url2.php`;

if ($?) {
    exit 2;
}

$response =~ m[(\d{9})];
if ($1 == "999999999") {
    print "no such a city.\n";
    exit;
}

$response = `$curlcmd http://www.weather.com.cn/html/weather_en/$1.shtml`;
if ($?) {
    exit 2;
}

my $weather = "Today is ";

$response =~ m[<dt style="float:left; width:300px;">Welcome!&nbsp;&nbsp;&nbsp;&nbsp;(.+) </dt>];
$weather .= "<$1>*";

$response =~ m[<title>(\S+)];
$weather .= " <$1>*";

@_ = ($response =~ m[<div class="fut_weatherbox">.*?</div>]sg);
if (@_ < 3) {
    print "No forecast available.\n";
    exit;
}
my %match;
for (1..3) {
    $_ = shift @_;
    m{<h3>(?<date>.+?)</h3>.*?<h4[^>]+?>(?<weather>.+)</h4>.*?<h4.+High:(?<hightemp>[^<]+)</h4>.*?<h4.+Low:(?<lowtemp>[^>]+)</h4>}s;
    %match = %+;
    $match{weather} =~ s[<br/>][]g;
    $weather .= " $match{date}: $match{weather}, $match{lowtemp} ~ $match{hightemp}*";

}
printf "%s\n", $weather;
