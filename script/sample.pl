use strict;
use warnings;

use Slack::RTM::Bot;

use Data::Dumper;

my $bot = Slack::RTM::Bot->new(
	token => $ARGV[0]
);


$bot->on({
        channel => 'test',
        text    => qr/.*/
    },
    sub {
        my ($response) = @_;
        print $response->{text}."\n";
    }
);

$bot->start_RTM;

$bot->say(
    channel => 'test',
    text    => '<!here> hello, world.'
);

$bot->say(
    channel => '@duck8823',
    text    => 'hello, world.'
);

sleep 300;
$bot->stop_RTM;
