BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use strict;
use warnings;

use Test::More 0.98;
use Test::Exception;

use Slack::RTM::Bot;

local $SIG{__WARN__} = sub { fail shift };

my $token = $ENV{SLACK_API_TOKEN};

subtest 'ENV', sub {
	SKIP: {
		skip 'No SLACK_API_TOKEN configured for testing.', 1 unless $token;
		my $bot = Slack::RTM::Bot->new(
			token => $token
		);

		$bot->start_RTM;
		isa_ok $bot->{client}, 'Slack::RTM::Bot::Client';

		$bot->stop_RTM;

		is defined $bot->{client}, '';
		is defined $bot->{child}, '';
	}
};

subtest 'invalid_token', sub {
	my $bot = Slack::RTM::Bot->new(
		token => 'invalid_token'
	);

	dies_ok {$bot->start_RTM};
};


done_testing;
