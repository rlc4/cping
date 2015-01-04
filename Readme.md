cping
=====

cping is a pretty simple little tool that will send back a randomized notice when a ping comes in.
It also fakes the ping time to a random interval, just because.

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
