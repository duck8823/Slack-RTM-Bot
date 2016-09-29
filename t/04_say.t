use strict;
use warnings;

use Test::More 0.98;
use Test::Exception;

use Slack::RTM::Bot;

local $SIG{__WARN__} = sub { fail shift };

my $bot = Slack::RTM::Bot->new(
	token => 'foobar'
);

dies_ok {
	$bot->say(
		'hoge'
	);
};
like $@, qr/argument is not a HASH or ARRAY\..*/;

dies_ok {
	$bot->say();
};
like $@, qr/argument is not a HASH or ARRAY\..*/;

dies_ok {
	$bot->say(
		'text' => 'hoge'
	)
};
like $@, qr/argument needs keys 'text' and 'channel'\..*/;

dies_ok {
	$bot->say(
		'channel' => 'hoge'
	)
};
like $@, qr/argument needs keys 'text' and 'channel'\..*/;

dies_ok {
	$bot->say(
		'channel' => 'hoge',
		'text' => 'hoge'
	)
};
like $@, qr/RTM not started.*/;

dies_ok {
	$bot->say(
		'channel', 'hoge',
		'text', 'hoge'
	)
};
like $@, qr/RTM not started.*/;

SKIP: {
my $token = $ENV{SLACK_API_TOKEN};
unless ($token) {
	skip 'No SLACK_API_TOKEN configured for testing.', 2;
}

my $tmp = "./test.tmp";

$bot = Slack::RTM::Bot->new(
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
}
done_testing();

