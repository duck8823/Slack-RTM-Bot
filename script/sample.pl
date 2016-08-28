use strict;
use warnings;

use Slack::RTM::Bot;

use Data::Dumper;

my $bot = Slack::RTM::Bot->new(
	token => $ARGV[0]
);

#$bot->on(
#	{},
#	sub {
#		my ($response) = @_;
#		print Dumper $response;
#	}
#);

$bot->start_RTM({debug => 0});

#$bot->say(
#	channel => '@shmaeda',
#	text    => '<!here> hello, world.'
#);

sleep 300;
$bot->stop_RTM;
