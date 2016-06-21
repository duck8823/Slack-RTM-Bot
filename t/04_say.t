use strict;
use warnings;

use Test::More 0.98;
use Test::Exception;

use Slack::RTM::Bot;

local $SIG{__WARN__} = sub { fail shift };

my $token = $ENV{SLACK_API_TOKEN};
unless ($token) {
	plan skip_all => 'No SLACK_API_TOKEN configured for testing.';
}

my $tmp = "./test.tmp";

my $bot = Slack::RTM::Bot->new(
	token => $token
);

$bot->add_action(
	{
		type => 'message',
		channel => 'test'
	},
	sub {
		my ($response) = shift;
		open TMP, ">$tmp" or die $!;
		print TMP $response->{text};
		close TMP;
	}
);
$bot->add_action(
	{
		type => 'error',
	},
	sub {
		my ($response) = shift;
		open TMP, ">$tmp" or fail $!;
		print TMP $response->{error}->{msg};
		close TMP;
	}
);

$bot->start_RTM;

$bot->say(
	channel => 'test',
	text    => 'return'
);

sleep 3;

open TMP, "$tmp" or fail $!;
my $result = <TMP>;
close TMP;
is $result, 'return';

dies_ok {
	$bot->say(
		channel => 'invalid_channel_id',
		text    => 'return'
	);
}

$bot->stop_RTM;
unlink $tmp;

done_testing();

