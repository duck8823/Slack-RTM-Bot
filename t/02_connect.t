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

subtest 'ENV', sub {
	my $bot = Slack::RTM::Bot->new(
		token => $token
	);

	$bot->start_RTM;

	isa_ok $bot->{client}, 'Slack::RTM::Bot::Client';
	is @{$bot->{children}}, 3;

	$bot->stop_RTM;

	is defined $bot->{client}, '';
	is defined $bot->{children}, '';
};

subtest 'invalid_token', sub {
	my $bot = Slack::RTM::Bot->new(
		token => 'invalid_token'
	);

	dies_ok {$bot->start_RTM};
};


done_testing;
