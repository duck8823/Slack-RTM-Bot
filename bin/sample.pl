use strict;
use warnings;

use Slack::RTM::Bot;

use Data::Dumper;

my $bot = Slack::RTM::Bot->new(
	token => '<API token>'
);

$bot->add_action(
	{},
	sub {
		my ($response) = @_;
		print Dumper $response;
	}
);

$bot->start_RTM;

$bot->say(
	channel => 'general',
	text    => '<!here> hello, world.'
);

$bot->say(
	channel => '@direct',
	text    => 'hello, world.'
);

$bot->stop_RTM;