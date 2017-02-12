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

local $SIG{__WARN__} = sub { fail shift };

use_ok $_ for qw(
    Slack::RTM::Bot
);

done_testing;

