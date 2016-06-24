use strict;
use warnings;

use Slack::RTM::Bot;

use Data::Dumper;

my $bot = Slack::RTM::Bot->new(
	token => $ARGV[0] 
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
	channel => '@shmaeda',
	text    => '<!here> hello, world.'
);

sleep 300;
$bot->stop_RTM;
