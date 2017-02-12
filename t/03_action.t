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

my $bot = Slack::RTM::Bot->new(
	token => 'foobar'
);
is @{$bot->{actions}}, 0;

my $return;
$bot->add_action(
	{
		foo => 'bar'
	},sub {
		$return = 1;
	}
);
is @{$bot->{actions}}, 1;

$bot->add_action(
	{
		foo => 'bar'
	},sub {
		$return = 2;
	}
);
is @{$bot->{actions}}, 2;

is ${$bot->{actions}}[0]->{events}->{foo}, 'bar';

is $return, undef;
&{${$bot->{actions}}[0]->{routine}};
is $return, 1;

done_testing();