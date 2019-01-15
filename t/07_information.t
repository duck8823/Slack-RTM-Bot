use strict;
use warnings;

use Test::More 0.98;
use Test::Exception;

use Slack::RTM::Bot;

local $SIG{__WARN__} = sub { fail shift };

my $info = Slack::RTM::Bot::Information->new(
	channels => [ { id => 'C123', name => 'Conversation' } ],
	users    => [ { id => 'U123', name => 'User' } ],
);

subtest 'find_conversation', sub {
	is $info->_find_conversation_id('Conversation'), 'C123', 'find conversation id.';
	is $info->_find_conversation_name('C123'), 'Conversation', 'find conversation name.';
};

subtest 'find_user', sub {
	is $info->_find_user_name('U123'), 'User', 'find user id.';
	is $info->_find_user_name('Undefined User'), undef, 'find undefined user id';
};


done_testing;
