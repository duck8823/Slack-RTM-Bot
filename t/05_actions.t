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
        type => qr/foo/
    }, sub {
        $ret = 'foo';
        $cnt++;
    }
);

$bot->add_action(
    {
        type => qr/bar/,
        hoge => qr/huga/,
    }, sub {
        $ret = 'bar';
        $cnt++;
    }
);



$bot->{ client } = Slack::RTM::Bot::Client->new(
    token   => $bot->{token},
    actions => $bot->{actions},
);

$bot->{ client }->_listen( $json->encode({'type' => 'foo'}) );
is $ret, 'foo', 'match type foo';

$bot->{ client }->_listen( $json->encode({'type' => 'bar'}) );
is $ret, 'foo', 'match type bar but mismatch another item';

$bot->{ client }->_listen( $json->encode({'type' => 'bar', 'hoge' => 'huga-'}) );
is $ret, 'bar', 'match type bar and another item hoge';

is $cnt, 2, 'tolal 2 matches';

done_testing();
