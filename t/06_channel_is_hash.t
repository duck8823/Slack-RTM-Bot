BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use strict;
use warnings;

use Test::More;
use Slack::RTM::Bot;
use JSON;

my $json = JSON->new->utf8;
my $ret  = '';
my $cnt  = 0;
my $bot  = Slack::RTM::Bot->new(
    token => 'foobar'
);

$bot->add_action(
    {
        type => qr/message/
    }, sub {
        my ( $ret ) = @_;
        is( $ret->{channel}, 'Test', 'channel was converted' );
        is( $ret->{user}, 'Anne', 'user was converted' );
        $cnt++;
    }
);

$bot->add_action(
    {
    }, sub {
        my ( $ret ) = @_;
        $cnt++;
    }
);


$bot->{ client } = Slack::RTM::Bot::Client->new(
    token   => $bot->{token},
    actions => $bot->{actions},
);
$bot->{client}->{info} = Slack::RTM::Bot::Information->new(
    channels => [ { id => 'C123', name => 'Test' } ],
    users    => [ { id => 'U123', name => 'Anne'  } ],
);


$bot->{ client }->_listen( $json->encode( {'type' => 'message', 'user' => 'U123', 'text' => 'This is  test.', 'channel' => 'C123'} ) );
is $cnt, 2, 'tolal 2 matches';
$bot->{ client }->_listen( $json->encode( {'type' => 'foo', 'channel' => +{} }) );
is $cnt, 3, 'tolal 3 matches';


done_testing();
