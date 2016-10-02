# NAME

Slack::RTM::Bot - This is a perl module helping to create slack bot with Real Time Messaging(RTM) API.

# SYNOPSIS

    use Slack::RTM::Bot;
    my $bot = Slack::RTM::Bot->new( token => '<API token>');

    $bot->on({
            channel => 'general',
            text    => qr/.*/
        },
        sub {
            my ($response) = @_;
            print $response->{text}."\n";
        }
    );

    $bot->start_RTM;

    $bot->say(
        channel => 'general',
        text    => '<!here> hello, world.'
    );

    $bot->say(
        channel => '@username',
        text    => 'hello, world.'
    );

    while(1) { sleep 10; print "I'm not dead\n"; }

# METHODS

## new

    method new(token => $token)

Constructs a [Slack::RTM::Bot](https://metacpan.org/pod/Slack::RTM::Bot) object.

The `$token` is the slack API token.

## on

    method on(\%event, $callback)

`$callback` will be executed when it fitted the `\%event` conditions.
The `\%event` key is equal to a key of json received from slack, and value is estimated as regex.

`$callback` is handed JSON object of message received from Slack.

## start\_RTM

    method start_RTM()

It start Real Time Messaging API.

## stop\_RTM

    method stop_RTM()

It stop Real Time Messaging API.

## say

    method say(%options)

It sent a message to a Slack. The channel name can be used to designate channel.
if you want to send a direct message, let designate the @username as a channel.

# SOURCE CODE

This is opensource software.

https://github.com/duck8823/Slack-RTM-Bot

# HOW TO CONTRIBUTE

## with installing
The fastest way to get started working with the code is to run the following commands:

    $ git clone https://github.com/duck8823/Slack-RTM-Bot.git
    $ cd Slack-RTM-Bot
    $ cpanm --installdeps .
    $ perl Build.PL
    $ ./Build
    $ ./Build install
    $ ./Build test  # run the tests

## without installing
or without installing Slack-RTM-Bot, run the following commands:

    $ git clone https://github.com/duck8823/Slack-RTM-Bot.git
    $ cd Slack-RTM-Bot
    $ cpanm --installdeps .  # install dependencies

and run your script with `-I/path/to/Slack-RTM-Bot/lib` option.

    $ perl -I/path/to/Slack-RTM-Bot/lib your_script.pl

## SEE ALSO

https://api.slack.com/rtm

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 Shunsuke Maeda

See LICENSE file.

# AUTHOR

Shunsuke Maeda &lt;duck8823@gmail.com>
