#
# Psycho irc bot -- an Xchat perl script;
# Author:
#   Hunt Xu <mhuntxu@gmail.com>
# Reference:
#   http://xchat.org/docs/xchat2-perl.html
#   http://xchatdata.net/Scripting/BasicPerlScript
#

use strict;
use warnings;
use Encode;
use Encode::Guess;
use Xchat qw( :all );
 
my $_name = "psycho";
my $_version = "0.4";
my $_description = "Psycho irc bot";
my $extra_msg = "[I'm $_name ^_^]";
my $mynick;
my $mysourcelink = "http://github.com/huntxu/psycho";

my %conf = (
    "#gentoo-cn"    =>  0,
    "#arch-cn"      =>  23,
    "#Psycho"       =>  31,
    "#fedora-zh"    =>  23,
    "#gzuc-linux"   =>  31,
    "#ownlinux"     =>  31,
    "#xfce-cn"      =>  4,
    "#xfce"         =>  0,
    "#ubuntu-cn-translators" => 23,
);

my %settings = (
    "weather"       =>  1,
    "dict"          =>  2,
    "url"           =>  4,
    "sayhi"         =>  8,
    "address"       =>  16,
);

sub selfprnt {
    my $content = $_[0];
    hook_timer(0, sub {prnt($content); return REMOVE;});
    return EAT_NONE;
}

sub botsay {
    chomp($_[0]);
    my $command = "say $_[0]\t$extra_msg";
    hook_timer(0, sub {command($command); return REMOVE;});
    return EAT_NONE;
}

sub on_join {
    my $channel = get_info("channel");
    return EAT_NONE unless (exists $conf{$channel});

    chomp($_[0][0]);    # nick
    return EAT_NONE if ($_[0][0] =~ /ChanServ/);
    if ($settings{"sayhi"} & $conf{$channel}) {
        botsay("$_[0][0]: hi")
    }
    return EAT_NONE;
}

sub check_msg {
    my $channel = get_info("channel");
    return EAT_NONE unless (exists $conf{$channel});
    return EAT_NONE if ($_[0][1] =~ /I'm psycho/);

    chomp($_[0][1]);    # text
    chomp($_[0][0]);    # nick
    my $if_react = $conf{$channel};
    my $is_me = $_[1];
    my $text = strip_code($_[0][1]);
    my $nick = strip_code(encode("utf8", $_[0][0]));
    my $msg;

    foreach(my @url=($text =~ m{(https?://[\w\./%-]+|www\.[\w/\.%-]+|[\w/\.%-]+\.(?:com|net|edu|cn|org|gov)[\w/\.%-]*|[\w/\.%-]\.(?:s?html|htm|php|asp|aspx)[\w\./%-]*)}ig)) {
	$msg = `geturltitle.pl $_`;
	unless ($?) {
            $msg = "Title: ".$msg;
            if ($settings{"url"} & $if_react) {
                botsay($msg);
            }
            else {
                selfprnt($msg);
            }
        }
        else {
	    selfprnt("Error getting url <$nick> $text.");
	}
    }

    if ( $text =~ /^~w(?:eather)?\s+(\S+)/i && ($settings{"weather"} & $if_react) ) {
        $msg = `weather.pl $1`;
    }
    elsif ( $text =~ /^~d(?:ict)?\s+(.+)/i && ($settings{"dict"} & $if_react) ) {
        $msg = `dict.pl $1`;
    }
    elsif ($text =~ /^~s(?:ource)?/i) {
        $msg = "I\'m here: $mysourcelink";
    }
    elsif ( $text =~ /^~a(?:dd)?\s+(\S+)/i && ($settings{"address"} & $if_react) ) {
        my $who = encode("utf8", $1);
        my $userinfo = user_info($who);
        if (defined($userinfo)) {
            $_ = $userinfo->{host};
            s/.*@(.*)/$1/;
            if ( /((2[0-4]\d|25[0-5]|[01]?\d\d?)\.){3}(2[0-4]\d|25[0-5]|[01]?\d\d?)/ ) {
                $msg = `getip.pl $_`;
                $msg = "$who $msg";
            }
            else {
                $msg = "$who hides in $_";
            }
        }
        else {
            return EAT_NONE;
        }
    }
    elsif ( $text =~ /^~h(?:elp)?/i && $if_react ) {
        $msg = "~d(ict) 查单词, ~w(eather) 查天气, ~a(dd) 查 ip 地址, ~s(ource) 源代码, ~h(elp) 本信息";
    }
    else {
        return EAT_NONE;
    }
    
    unless ($?) {
        if ($is_me) {
            botsay("$msg");
        }
        else {
            botsay("$nick: $msg");
        }
    }
    else {
        selfprnt("An error occured: <$nick> $text.\nResult: $msg");
    }

    return EAT_NONE;
}

sub check_hi_msg {
    $_[0][1] =~ s/^$mynick\S+\s+//;
    return check_msg(@_);
}

# Script starts here;
register($_name, $_version, $_description);
prnt("Loaded $_name $_version [$_description]");
$mynick = get_info("nick");
 
hook_print('Channel Message', \&check_msg, {data => 0});
hook_print('Channel Msg Hilight', \&check_hi_msg, {data => 0});
hook_print('Your Message', \&check_msg, {data => 1});
hook_print('Join', \&on_join);
