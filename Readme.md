# cping #

cping is a pretty simple little tool that will send back a randomized notice when a ping comes in.
It also fakes the ping time to a random interval, just because.

Pings are amusing or annoying, either way have fun with people that ping you.
This module sets up a store of ping response messages to send back to anyone that pings you.
For right now, the ping response they get back will be something random from this (for non-
cryptographic values of 'random').

## Requirements ##
 - Irssi (duh)
 - DBD::SQLite
   - A database is used to store the pings and also to record the history of pings that occurred.

## Installation ##
 - Copy cping.pl to ~/.irssi/scripts/
 - In irssi: %/script load cping%  or %/run cping%
 - Optional to have it start with irssi: cd ~/.irssi/scripts/autorun ; ln -s ../cping .

## Commands ##
 * cping
   * Lists the available commands in cping
 * cping help                  
   * this help
 * cping stats
   * Show some simple stats (future plan)
 * cping history
   * shows the history of ping responses sent
 * cping history <NICK>
   * shows the history for just that nick
 * cping add <message>
   * adds a ping response to the dataset, shows the messageID
 * cping list
   * show the list of current ping messages, including the messageID
 * cping search <MATCH STRING>
   * Using the SQLite "like" syntax.  MATCH STRING is wrapped in %%s so it will match any portion of a message or word.
 * cping disable <messageID>
   * disables a messageID from the rotation, this seems a better idea than deleting messages as the message may have been sent out in the past and thus be referenced using /cpan history
 * cping enable <messageID>
   * enables a messageID to be used as part of the random sample
 * cping init
   * Initializes some basic stuff, like the db_handle.  If you change the cping_db_file setting, you should re-run this

## Settings ##

The following settings (with defaults) are used by cping:

 * cping_db_file = ~/.irssi/pings.db
   - Where the database that cping uses exists, including the database filename itself.
 * cping_debug = OFF
   - Should debugging information be shown (just leave this alone).
 * cping_faketime = ON
   - If this is set to 'ON' cping will lie about the ping time, by as much as an hour. 
