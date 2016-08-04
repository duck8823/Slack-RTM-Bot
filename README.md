# NAME

Slack::RTM::Bot - This is a perl module helping to create slack bot with Real Time Messaging(RTM) API.

# SYNOPSIS

    use Slack::RTM::Bot;
    my $bot = Slack::RTM::Bot->new( token => '<API token>');

    $bot->on({
            channel => 'general',
            text    => /.*/
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

    $bot->say({
        channel => '@username',
        text    => 'hello, world.'
    });

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

## SEE ALSO

https://api.slack.com/rtm

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 Shunsuke Maeda

See LICENSE file.

# AUTHOR

Shunsuke Maeda <duck8823@gmail.com>
