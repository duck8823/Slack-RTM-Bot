package Slack::RTM::Bot;

use 5.008001;
use strict;
use warnings;

use Slack::RTM::Bot::Client;

our $VERSION = "0.01";

sub new {
	my $pkg = shift;
	my $self = {
		@_
	};
	die 'need token!' unless $self->{token};
	return bless $self, $pkg;
}

sub start_RTM {
	my $self = shift;
	my $client = $self->_connect;

	my $parent = $$;

	my $pid_1 = fork;
	unless($pid_1) {
		while (kill 0, $parent) {
			$client->read;
			sleep 1;
		}
	}

	my $pid_2 = fork;
	unless($pid_2) {
		my $i = 0;
		while (kill 0, $parent) {
			$client->write(
				id   => $i++,
				type => 'ping'
			);
			sleep 30;
		}
	}

	$self->{children} = [$pid_1, $pid_2];
}

sub stop_RTM {
	my $self = shift;
	$self->{client}->disconnect;
	undef $self->{client};

	kill 9, @{$self->{children}};
	undef $self->{children};
}

sub _connect {
	my $self = shift;

	my $client = Slack::RTM::Bot::Client->new(
		token   => $self->{token},
		actions => $self->{actions}
	);
	$client->connect($self->{token});

	$self->{client} = $client;
	return $client;
}

sub say {
	my $self = shift;
	my $args = {@_};

	die "RTM not started." unless $self->{client};
	my $client = $self->{client};

	if(!defined $args->{text} || !defined $args->{channel}) {
		die;
	}

	$client->write(
		type    => 'message',
		subtype => 'bot_message',
		bot_id  => $self->{client}->{info}->{self}->{id},
		%$args,
		channel => $self->{client}->{info}->_find_channel_id($args->{channel}),
	);
}

sub add_action {
	my $self = shift;
	die "RTM already started." if $self->{info};
	my ($events, $routine) = @_;
	push @{$self->{actions}}, {
			events  => $events,
			routine => $routine
		};
}

1;
__END__

=encoding utf-8

=head1 NAME

Slack::RTM::Bot - This is a perl module helping to create slack bot with Real Time Messaging(RTM) API.

=head1 SYNOPSIS

    use Slack::RTM::Bot;
    my $bot = Slack::RTM::Bot->new( token => '<API token>');

    $bot->add_action({
            channel => 'general',
            text    => '.*'
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

=head1 METHODS

=head2 new

  method new(token => $token)

Constructs a L<Slack::RTM::Bot> object.

The C<$token> is the slack API token.

=head2 add_action

  method add_action(\%event, $callback)

C<$callback> will be executed when it fitted the C<\%event> conditions.
The C<\%event> key is equal to a key of json received from slack, and value is estimated as regex.

C<$callback> is handed JSON object of message received from Slack.

=head2 start_RTM

  method start_RTM()

It start Real Time Messaging API.

=head2 stop_RTM

  method stop_RTM()

It stop Real Time Messaging API.

=head2 say

  method say(%options)

It sent a message to a Slack. The channel name can be used to designate channel.
if you want to send a direct message, let designate the @username as a channel.

=head1 SOURCE CODE

This is opensource software.

https://github.com/duck8823/Slack-RTM-Bot

=head2 SEE ALSO

https://api.slack.com/rtm

=head1 LICENSE

The MIT License (MIT)

Copyright (c) 2016 Shunsuke Maeda

See LICENSE file.

=head1 AUTHOR

Shunsuke Maeda E<lt>duck8823@gmail.comE<gt>

=cut

