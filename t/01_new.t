use strict;
use warnings;

use Test::More 0.98;
use Test::Exception;

use Slack::RTM::Bot;

local $SIG{__WARN__} = sub { fail shift };

my $bot = Slack::RTM::Bot->new(
	token => 'foobar'
);
isa_ok $bot, 'Slack::RTM::Bot';

dies_ok { Slack::RTM::Bot->new(); };

done_testing;