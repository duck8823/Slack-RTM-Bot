package Slack::RTM::Bot;

use 5.008001;
use strict;
use warnings;

use POSIX qw/sys_wait_h/;

use JSON;
use Slack::RTM::Bot::Client;

our $VERSION = "1.13";

pipe(READH, WRITEH);
select(WRITEH);$|=1;
pipe(READH2, WRITEH2);
select(WRITEH2);$|=1;
select(STDOUT);

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
	my ($sub) = @_;
	$self->_connect($self->{options});

	my $parent = $$;

	if ($^O ne 'MSWin32') {
		my @children = ();

		my $pid = fork;
		push @children, $pid;
		unless ($pid) {
			while (1) {
				unless (kill 0, $pid) {
					kill 9, $pid;
					waitpid($pid, WUNTRACED);
					last;
				}
				print WRITEH "\n";
				sleep 1;
			}
		} else {
			my $pid = fork;
			push @children, $pid;
			unless ($pid) {
				$self->{client}->{pids} = [$parent, @children];
				my $i = 0;
				while (1) {
					unless (kill 0, $parent) {
						kill 9, $pid;
						waitpid($pid, WUNTRACED);
						last;
					}
					if ($self->{client}->read) {
						print WRITEH2 "\n";
					}
					(my $buffer = <READH>) =~ s/\n.*$//;
					if ($buffer) {
						$self->{client}->write(
							%{JSON::from_json(Encode::decode_utf8($buffer))}
						);
					}
					if (++$i % 30 == 0) {
						$self->{client}->write(
							id   => $i,
							type => 'ping'
						);
					}
				}
			} else {
				$self->{children} = \@children;
				# wait until connected
				<READH2>;
				&$sub($self) if $sub;
			}
		};
	} else {
		require threads;
		require Thread::Queue;

		threads->create(
			sub {
				while (kill 0, $parent) {
					print WRITEH "\n";
					sleep 1;
				}
			}
		)->detach;

		threads->create(
			sub {
				my $i = 0;
				while (kill 0, $parent) {
					if ($self->{client}->read) {
						print WRITEH2 "\n";
					}
					(my $buffer = <READH>) =~ s/\n.*$//;
					if ($buffer) {
						$self->{client}->write(
							%{JSON::from_json(Encode::decode_utf8($buffer))}
						);
					}
					if (++$i % 30 == 0) {
						$self->{client}->write(
							id   => $i,
							type => 'ping'
						);
					}
				}
			}
		)->detach;

		$self->{queue} = Thread::Queue->new();
		$self->{worker} = threads->create(sub {
			while (defined(my $req = $self->{queue}->dequeue())) {
				print WRITEH $req;
			}
		});

		# wait until connected
		<READH2>;
		&$sub($self) if $sub;
	}
}

sub stop_RTM {
	my $self = shift;

	sleep 1;
	$self->{client}->disconnect;
	undef $self->{client};

	if ($^O ne 'MSWin32') {
		for my $child (@{$self->{children}}) {
			kill 9, $child;
			waitpid($child, WUNTRACED);
		}
		undef $self->{children};
	} else {
		$self->{queue}->end();
		$self->{worker}->join();
	}
}

sub _connect {
	my $self = shift;

	my $client = Slack::RTM::Bot::Client->new(
		token   => $self->{token},
		actions => $self->{actions},
		options => $self->{options}
	);
	$client->connect($self->{token});

	$self->{client} = $client;
}

sub say {
	my $self = shift;
	my $args;
	if(!@_ || scalar @_ % 2 != 0) {
		die "argument is not a HASH or ARRAY."
	}
	$args = {@_};
	if(!defined $args->{text} || !defined $args->{channel}) {
		die "argument needs keys 'text' and 'channel'.";
	}

	die "RTM not started." unless $self->{client};

	my $request = JSON::to_json({
		type    => 'message',
		subtype => 'bot_message',
		bot_id  => $self->{client}->{info}->{self}->{id},
		%$args,
		channel => $self->{client}->find_conversation_id($args->{channel})
	})."\n";
	print WRITEH $request;
}

sub on {
	my $self = shift;
	die "RTM already started." if $self->{info};
	my ($events, $routine) = @_;
	push @{$self->{actions}}, {
			events  => $events,
			routine => $routine
		};
}

sub add_action {
	my $self = shift;
	$self->on(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Slack::RTM::Bot - This is a perl module helping to create slack bot with Real Time Messaging(RTM) API.

=head1 SYNOPSIS

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

    $bot->start_RTM(sub {

        $bot->say(
            channel => 'general',
            text    => '<!here> hello, world.'
        );

        $bot->say(
            channel => '@username',
            text    => 'hello, world.'
        );

        while(1) { sleep 10; print "I'm not dead\n"; }
    });

=head1 METHODS

=head2 new

  method new(token => $token)

Constructs a L<Slack::RTM::Bot> object.

The C<$token> is the slack API token.

=head2 on

  method on(\%event, $callback)

C<$callback> will be executed when it fitted the C<\%event> conditions.
The C<\%event> key is equal to a key of json received from slack, and value is estimated as regex.

C<$callback> is handed JSON object of message received from Slack.

=head2 start_RTM

  method start_RTM($callback)

It start Real Time Messaging API.
C<$callback> will be executed when establish connection.
C<start_RTM> make child process. Thus, you must call C<stop_RTM> if you want to kill child processes before stop main process.

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

=head1 HOW TO CONTRIBUTE

=head2 with installing
The fastest way to get started working with the code is to run the following commands:

  $ git clone https://github.com/duck8823/Slack-RTM-Bot.git
  $ cd Slack-RTM-Bot
  $ cpanm --installdeps .
  $ perl Build.PL
  $ ./Build
  $ ./Build install
  $ ./Build test  # run the tests

=head2 without installing
or without installing Slack-RTM-Bot, run the following commands:

  $ git clone https://github.com/duck8823/Slack-RTM-Bot.git
  $ cd Slack-RTM-Bot
  $ cpanm --installdeps .  # install dependencies

and run your script with `-I/path/to/Slack-RTM-Bot/lib` option.

  $ perl -I/path/to/Slack-RTM-Bot/lib your_script.pl

=head1 SEE ALSO

https://api.slack.com/rtm

=head1 LICENSE

The MIT License (MIT)

Copyright (c) 2016 Shunsuke Maeda

See LICENSE file.

=head1 AUTHOR

Shunsuke Maeda E<lt>duck8823@gmail.comE<gt>

=cut

