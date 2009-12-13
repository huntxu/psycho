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
my $_version = "0.1";
my $_description = "Psycho irc bot";
my $extra_msg = "[I'm $_name ^_^]";

my %conf = (
    "#gentoo-cn"    =>  0,
    "#arch-cn"      =>  7,
    "#Psycho"       =>  15,
    "#fedora-zh"    =>  7,
    "#gzuc-linux"   =>  15,
    "#ownlinux"     =>  15,
    "#xfce-cn"      =>  4,
    "#xfce"         =>  0,
    "#ubuntu-cn-translators" => 7,
);

my %settings = (
    "weather"       =>  1,
    "dict"          =>  2,
    "url"           =>  4,
    "sayhi"         =>  8,
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

sub show_help {
}

sub on_join {
    my $channel = get_info("channel");
    return EAT_NONE unless (exists $conf{$channel});

    chomp($_[0][0]);    # nick
    if ($settings{"sayhi"} & $conf{$channel}) {
        botsay("$_[0][0]: hi")
    }
    return EAT_NONE;
}

sub check_msg {
    my $channel = get_info("channel");
    return EAT_NONE unless (exists $conf{$channel});

    chomp($_[0][1]);    # text
    chomp($_[0][0]);    # nick
    my $if_react = $conf{$channel};
    my $is_me = $_[1];
    my $text = $_[0][1];
    my $nick = encode("utf8", $_[0][0]);
    my $msg;

    foreach(my @url=($text =~ m{(https?://[\w\./]+|www\.[\w/\.]+|[\w/\.]+\.(?:com|net|edu|cn|org|gov)[\w/\.]*|[\w/\.]\.(?:s?html|htm|php|asp|aspx)[\w\./]*)}ig)) {
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
    elsif ($? == 1) {
        show_help;
    }
    else {
        selfprnt("An error occured: <$nick> $text.\nResult: $msg");
    }

    return EAT_NONE;
}

# Script starts here;
register($_name, $_version, $_description);
prnt("Loaded $_name $_version [$_description]");
 
hook_print('Channel Message', \&check_msg, {data => 0});
hook_print('Your Message', \&check_msg, {data => 1});
hook_print('Join', \&on_join);

