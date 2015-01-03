use Irssi;
use strict;
use Getopt::Long qw(GetOptionsFromString);
use vars qw($VERSION %IRSSI);
use DBI;

$VERSION="0.0.a";
%IRSSI = (
    authors=> 'luwenth',
    contact=> 'luwenth@netscum.com',
    name=> 'cust_ping',
    description=> 'provides a customized(random) ping response',
    license=> 'GPL v2',
    url=> 'NA',
);
my $dbh;
# cping.pl
# for irssi 0.8.16 by luwenth@netscum.com

################
###
#
# Version 0.0.a
#    Initial creation, let's see how fast/far this will go
#
###
################
###
#
# BUGS
#   There are no bugs, only features that were not documented!
#
###
################

# catch the ctcp ping message coming in
# pick a response, and send back!
sub sighandler_cping {
    my ($server, $args, $nick, $address, $target) = @_;
    my $debug = 0;  # default to false
    Irssi::print("CTCP %_Ping%_ from %_$nick%_",MSGLEVEL_CTCPS);
    if ( Irssi::settings_get_bool('cping_debug') ) {
        $debug = 1;
        cping_print(" < You just got pinged from $nick");
        cping_print(" < Server        | $server");
        cping_print(" < Secs uSecs    | $args");
        cping_print(" < Nick          | $nick");
        cping_print(" < Address       | $address");
        cping_print(" < Target        | $target");
        # use Data::Dumper;
        # Irssi::print(Dumper($server));
    }


    # I think normally what is supposed to happen:
    #   The remote client tells me a time: secs usecs
    #   I compare this with my time, subtracting their time from my time
    #   I add this delta to my time, and resond: secs usecs
    #   When they get my times, they do the same subtraction
    #   and should come up with full round-trip ping time
    #
    #   Use this information to mess with people. :)
    my ($secs,$usecs) = split(/\s+/,$args);
    if (Irssi::settings_get_bool('cping_faketime') ) {
        # make up some numbers!  We will be within an hour of the ping
        $secs = int($secs) - int(rand(3600)) ;
        $usecs = int($usecs) - int(rand(99999)) ;
    }
    else {
        use Time::HiRes qw(gettimeofday);
        my ($lsec,$lusec) = gettimeofday();
        $secs = int($lsec) - (int($lsec) - int($secs));
        $usecs = int($lusec) - (int($lusec) - int($usecs));
    }

    cping_print(" > Secs uSecs    | $secs $usecs");
    Irssi::signal_emit("ctcp reply ping",$server, $secs . " " . $usecs,$nick, $address, $target);
    Irssi::signal_emit("message irc notice", $server, cping_getmsg($nick,$server), $nick, $address, $target);
    # Irssi::signal_emit("");

    # no more processing for ctcp msg ping, we've handled it completely and don't want anything else to happen
    Irssi::signal_stop();
    if($debug) {
        cping_print(" > Done sending, signal stopped",MSGLEVEL_CRAP);
    }
}

sub cping_help {
    # print out something helpful, or not.
    my $HELP = << "___EOH___";
%_cping%_

Pings are amusing or annoying, either way have fun with people that ping you.
This module sets up a store of ping response messages to send back to anyone that pings you.
For right now, the ping response they get back will be something random from this (for non-
cryptographic values of 'random').

Commands:
cping                       - this help
cping help                  - this help
cping stats
cping history               - shows the history of ping responses sent
    - cping history <NICK>  - shows the history for just that nick
cping add <message>         - adds a ping response to the dataset, shows the messageID
        - currently the message is a straight-up text string that will be sent back as-is
cping list                  - show the list of current ping messages
cping search <regexp>       - seems obvious, search for something and get a list of hits
cping disable <messageID>   - disables a messageID from the rotation
cping enable <messageID>    - enables a messageID back in the rotation
cping init                  - initializes some basic stuff, like the db_handle.
    - if you change the cping_db_file setting, you should re-run this

See also: there is nothing like this
___EOH___
    Irssi::print($HELP ,MSGLEVEL_CRAP);
}

# send the user some stats
sub cping_stats {
    cping_print("There will be some stats here");
    # count of pings recvd
    # count of each ping response sent, ordered top to least (no 0s)
}

### a couple helper functions
sub cping_print {
    Irssi::print("%_cping%_: " . join(" ",@_) ,MSGLEVEL_CRAP);
}

sub cping_getmsg {
    my $nick = shift || "TestingUser";
    my $SERVER = shift;
    my $servname = $SERVER->{'chatnet'} . ":" . $SERVER->{'address'};
    # stuff we're going to use...
    my ($cur,$end,$msg,$msgID);

    $dbh = DBI->connect("dbi:SQLite:dbname=" . Irssi::settings_get_str('cping_db_file'),"","");
    my $qry = $dbh->prepare("select count(*) from messages where enable=1");
    if ( $qry->execute() ) {
        my $count = ($qry->fetchrow())[0];
        if ( Irssi::settings_get_bool('cping_debug') ) {
            if ($count) {
                cping_print("Found $count available ping messages, selecting at random.");
            } else {
                cping_print("Found 0 available ping messages, sending default.");
            }
        }
        if ($count > 0) {
            $end = int(rand($count)); 
            $qry = $dbh->prepare("select msgID,msg from messages where enable = 1");
            $qry->execute();
            for ($cur = 0; $cur <= $end ; $cur++) {
                ($msgID,$msg) = $qry->fetchrow_array();
                if ( Irssi::settings_get_bool('cping_debug') ) {
                    cping_print("end: $end cur: $cur msgID: $msgID msg: $msg");
                }
            }
            # update history
            $qry = $dbh->prepare("insert into history (msgID,timestamp,network,nick) values (?,?,?,?)");
            if ($qry->execute($msgID,time(),$servname,$nick)) {
                if (Irssi::settings_get_bool('cping_debug') ) {
                    cping_print("Recorded history! " . time() ." -> $msgID -> $servname -> $nick");
                }
            }
            return $msg;
        } else {
            return "This is a test ping, in the event of a real ping you would have been pinged.";
        }
    }
}

### sets up the db, if there wasn't one before.
### Future versions - update the DB to any new structure
sub cping_init() {
    $dbh = DBI->connect("dbi:SQLite:dbname=" . Irssi::settings_get_str('cping_db_file'),"","");
    if (! $dbh) {
        cping_print("Ooops!  Can't get the db ready, please verify setting: %_/set cping_db_file%_");
    }
    my $sth = $dbh->table_info( undef, undef, "meta", "TABLE");
    $sth->execute;
    if (! scalar $sth->fetchrow_array ) {
        # if we didn't have the meta table, we need to set up all of our tables
        cping_print("No database found, creating a new one in " . Irssi::settings_get_sr('cping_db_file') 
                . " this can be changed with: %_/set cping_db_file%_");
        $dbh->do( "CREATE TABLE meta (key, value)" );
        $dbh->do( "create table messages (msgID INTEGER PRIMARY KEY, enable integer default 1, msg)" );
        $dbh->do( "CREATE TABLE history (msgID,timestamp,network,nick)" );
        $dbh->do( "INSERT INTO meta VALUES ('version','alpha')" );
    }
    # TODO: check the version number of the table and update as needed
}

sub cping_history {
    my ($data,$server,$item) = @_;
    $dbh = DBI->connect("dbi:SQLite:dbname=" . Irssi::settings_get_str('cping_db_file'),"","");
    my $qry;
    
    if ( Irssi::settings_get_bool('cping_debug') ) {
        cping_print("history: $data");
    }
    if ($data) {
        $qry = $dbh->prepare("select timestamp,network,nick,msg from history,messages "
                            . "where messages.msgID = history.msgID and nick like ? order by timestamp");
        $qry->execute($data);
    } else {
        $qry = $dbh->prepare("select timestamp,network,nick,msg from history,messages "
                            . "where messages.msgID = history.msgID order by timestamp");
        $qry->execute();
    }
    while (my @d = $qry->fetchrow_array() ) {
        cping_print( join(" - ",@d) );
    }
    if ($qry->rows < 1) {
        cping_print("Failed to add your message. Did you update your db location or something? try "
                    . "%_cping init%_");
    }
}

sub cping_add {
    my ($data,$server,$item) = @_;
    $dbh = DBI->connect("dbi:SQLite:dbname=" . Irssi::settings_get_str('cping_db_file'),"","");
    my $qry = $dbh->prepare("insert into messages (msg) values (?)");
    if ( !  $qry->execute($data) ) {
        cping_print("Failed to add your message. Did you update your db location or something? try "
                    . "%_cping init%_");
    } else {
        cping_print("Addeed ping message -> $data");
    }
}
sub cping_list {
    cping_search("%\x01No ping messages found, please use %_cping add %_");
}

sub cping_search {
    my ($data,$server,$item) = @_;
    my ($match,$errmsg) = split(/\x01/,$data);
    
    $dbh = DBI->connect("dbi:SQLite:dbname=" . Irssi::settings_get_str('cping_db_file'),"","");
    my $qry = $dbh->prepare("select enable,msgID, msg from messages where msg like ?");
    if ($match) {
        $qry->execute("%".$match."%");
    } else {
        $qry->execture("%");
    }
    while (my @d = $qry->fetchrow_array() ) {
            my $msg = "";
            $msg = "%8<DISABLED>%8 " if (! $d[0]);
            $msg = $msg . "ID: ". $d[1] ." ";
            $msg = $msg . "Message: ";
            $d[2] =~ s/($match)/%U$1%U/g;
            $msg = $msg . $d[2];
            cping_print($msg);
    }
    if (! $qry->rows ){
        if ($errmsg) {
            cping_print($errmsg);
        } else {
            cping_print("No ping messages matched: $match");
        }
    }
}

sub cping_disable {
    my ($data,$server,$item) = @_;
    my ($ID, $en);
    ($ID,$en)= split(/\x01/,$data);
    $en = 0 if (! $en);
    $en = int($en);
    my $msgID = int($ID);
    $dbh = DBI->connect("dbi:SQLite:dbname=" . Irssi::settings_get_str('cping_db_file'),"","");
    my $qry = $dbh->prepare("update messages set enable=? where msgID = ?");
    if ( $qry->execute($en, $msgID) ) {
        if ($en) {
            cping_print("ID $msgID has been enabled.");
        } else {
            cping_print("ID $msgID has been disabled.");
        }
    } else {
        cping_print("I don't think message with ID $msgID was disabled. :(");
    }
}

sub cping_enable {
    my($data,$server,$item) = @_;
    cping_disable($data . "\x011");
}

sub cping {
    my ($data,$server,$witem) = @_;
    Irssi::command_runsub('cping',$data,$server,$witem);
}

# add some settings for the user to twitch
Irssi::settings_add_bool('cping', 'cping_faketime', 0);
Irssi::settings_add_bool('cping', 'cping_debug', 1);
Irssi::settings_add_str('cping', 'cping_db_file', Irssi::get_irssi_dir . '/pings.db');
# add the signal for incoming pings to be caught
Irssi::signal_add('ctcp msg ping', 'sighandler_cping');
Irssi::signal_add('setup changed', \&cping_init);
# add out commands
Irssi::command_bind('cping','cping');
Irssi::command_bind('cping stats',\&cping_stats);
Irssi::command_bind('cping history',\&cping_history);
Irssi::command_bind('cping add',\&cping_add);
Irssi::command_bind('cping list',\&cping_list);
Irssi::command_bind('cping search',\&cping_search);
Irssi::command_bind('cping disable',\&cping_disable);
Irssi::command_bind('cping enable',\&cping_enable);
Irssi::command_bind('cping init',\&cping_init);

cping_init;
