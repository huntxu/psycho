#!/usr/bin/perl -w
use strict;
use Encode;
use Encode::Guess;
use Net::IRC;

sub to_utf8 {
    my ( $msg, $charset ) = @_;
    $msg = encode( "utf8", decode( $charset, $msg ) );
    return $msg;
}

sub on_connect {
    my $self = shift;
    $self->join("#arch-cn");
    $self->join("#Psycho");
}

sub on_line {
    my ( $self, $event ) = @_;
    my ( $nick, $arg ) = ( $event->nick, $event->args );

    my $charset = guess_encoding( $arg, qw/cp936/ );
    unless ( ( $charset =~ /.*or.*/ )
        || ( $charset->mime_name eq "UTF-8" )
        || ( $charset->mime_name eq "US-ASCII" ) )
    {
        $arg = to_utf8( $arg, $charset );
        $self->privmsg( $event->to, "$nick says \"$arg\", but not in utf8." );
    }

    print "<$nick> $arg\n";

    foreach (
        my @url = (
            $arg =~
m{(https?://[\w\./]+|www\.[\w/\.]+|[\w/\.]+\.(?:com|net|edu|cn|org|gov)[\w/\.]*|[\w/\.]\.(?:s?html|htm|php|asp|aspx)[\w\./]*)}ig
        )
      )
    {
        my $title = `./geturltitle.pl $_`;
        unless ($?) {
            $title = "Title: " . $title;
            $self->privmsg( $event->to, $title );
        }
        else {
            print "$title\n";
        }
    }

    if ( $arg =~ /^~w(?:eather)?\s+(\S+)/i ) {
        my $weather = `./weather.pl $1`;
        unless ($?) {
            $self->privmsg( $event->to, "$nick $weather" );
        }
        elsif ( $? == 1 ) {
            $self->privmsg( $event->to, "$nick Usage: ~w(eather) cityname\n" );
        }
        else {
            print "$weather\n";
        }
    }

    if ( $arg =~ /^~d(?:ict)?\s+(\S+)/i ) {
        my $word = `./dict.pl $1`;
        if ( $? == 0 ) {
            $self->privmsg( $event->to, "$nick $word" );
        }
        elsif ( $? == 1 ) {
            $self->privmsg( $event->to,
"$nick Usage:  ~d(ict) word\n        ~d(ict) [sound] -- 查找近音单词\n"
            );
        }
        else {
            print "$word\n";
        }
    }

    if ( $arg =~ /go home/i && $nick eq "huntxu" ) {
        $self->privmsg( $event->to, 'BYE BYE~~' );
        $self->quit;
        exit 0;
    }
}

sub on_msg {
    my ( $self, $event ) = @_;
    my ($nick) = ( $event->nick );
    $self->privmsg( $nick, "本 bot 不接受私聊\n" );
}

sub on_cversion {
    my ( $self, $event ) = @_;
    my ($nick) = ( $event->nick );
    print "receive ctcp version request from " . $nick . "\n";
    print $event->type . "\n";
    $self->ctcp_reply( $nick, "VERSION 0.0.5 Psycho." );
}

my $irc  = new Net::IRC;
my $conn = $irc->newconn(
    Nick     => "psycho",
    Server   => "irc.oftc.net",
    Port     => 6667,
    Username => "psycho",
    Ircname  => "I'm a bot",
    SSL      => 0
);
$conn->add_global_handler( "376",      \&on_connect );
$conn->add_global_handler( "cversion", \&on_cversion );

#$conn->add_global_handler( "disconnect", \&on_disconnect );
$conn->add_handler( 'public', \&on_line );
$conn->add_handler( 'msg',    \&on_msg );
$irc->start;

