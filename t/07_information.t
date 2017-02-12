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

my $info = Slack::RTM::Bot::Information->new(
	channels => [ { id => 'C123', name => 'Public Channel' } ],
	users    => [ { id => 'U123', name => 'User' } ],
	groups   => [ { id => 'G123', name => 'Private Channel' } ]
);

subtest 'find_user', sub {
	is $info->_find_user_name('U123'), 'User', 'find user id.';
	dies_ok {$info->_find_user_name('Undefined User')}
};

subtest 'find_public_channel', sub {
	is $info->_find_channel_id('Public Channel'), 'C123', 'find public channel id.';
	is $info->_find_channel_name('C123'), 'Public Channel', 'find public channel name.';

	is $info->_find_channel_id('Private Channel'), undef, 'find undefined channel id.';
	is $info->_find_channel_name('G123'), undef, 'find undefined channel name.';
};

subtest 'find_private_channel', sub {
	is $info->_find_group_id('Private Channel'), 'G123', 'find private channel id.';
	is $info->_find_group_name('G123'), 'Private Channel', 'find private channel name.';

	is $info->_find_group_id('Public Channel'), undef, 'find undefined channel id.';
	is $info->_find_group_name('C123'), undef, 'find undefined channel name.';
};

subtest 'find_channel', sub {
	is $info->_find_channel_or_group_id('Public Channel'), 'C123', 'find public channel id.';
	is $info->_find_channel_or_group_id('Private Channel'), 'G123', 'find private channel id.';

	dies_ok {$info->_find_channel_or_group_id('Undefined Channel')}

	is $info->_find_channel_or_group_name('C123'), 'Public Channel', 'find public channel name.';
	is $info->_find_channel_or_group_name('G123'), 'Private Channel', 'find private channel name.';

	dies_ok {$info->_find_channel_or_group_name('U123')};
};

done_testing;
