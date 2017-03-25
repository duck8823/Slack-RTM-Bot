package Slack::RTM::Bot::Client;

use strict;
use warnings;

use JSON;
use Encode;
use Data::Dumper;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use LWP::Protocol::https;

use Protocol::WebSocket::Client;
use IO::Socket::SSL qw/SSL_VERIFY_NONE/;

use Slack::RTM::Bot::Information;
use Slack::RTM::Bot::Response;

my $ua = LWP::UserAgent->new(
	ssl_opts => {
		verify_hostname => 0,
		SSL_verify_mode => SSL_VERIFY_NONE
	}
);
$ua->agent('Slack::RTM::Bot');

sub new {
	my $pkg = shift;
	my $self = {
		@_
	};
	die "token is required." unless $self->{token};
	return bless $self, $pkg;
}

sub connect {
	my $self = shift;
	my ($token) = @_;

	my $res = $ua->request(POST 'https://slack.com/api/rtm.start', [ token => $token ]);
	my $content;
	eval {
		$content = JSON::from_json($res->content);
	};
	if ($@) {
		die 'response fail:'.Dumper $res->content;
	}
	die 'response fail: '.$res->content unless ($content->{ok});

	$self->{info} = Slack::RTM::Bot::Information->new(%{$content});
	$res = $ua->request(POST 'https://slack.com/api/im.list', [ token => $token ]);
	eval {
		$content = JSON::from_json($res->content);
	};
	if ($@) {
		die 'response fail:'.Dumper $res->content;
	}
	die 'response fail: '.$res->content unless ($content->{ok});

	for my $im (@{$content->{ims}}) {
		my $name = $self->{info}->_find_user_name($im->{user});
		$self->{info}->{channels}->{$im->{id}} = { %$im, name => '@'.$name };
	}
	$self->_connect;
}

sub _connect {
	my $self = shift;
	my ($host) = $self->{info}->{url} =~ m{wss://(.+)/websocket};
	my $socket = IO::Socket::SSL->new(
		SSL_verify_mode => SSL_VERIFY_NONE,
		PeerHost => $host,
		PeerPort => 443
	);
	$socket->blocking(0);
	$socket->connect;

	my $ws_client = Protocol::WebSocket::Client->new(url => $self->{info}->{url});
	$ws_client->{hs}->req->{max_message_size} = $self->{options}->{max_message_size} if $self->{options}->{max_message_size};
	$ws_client->{hs}->res->{max_message_size} = $self->{options}->{max_message_size} if $self->{options}->{max_message_size};
	$ws_client->on(read => sub {
			my ($cli, $buffer) = @_;
			$self->_listen($buffer);
		});
	$ws_client->on(write => sub {
			my ($cli, $buffer) = @_;
			syswrite $socket, $buffer;
		});
	$ws_client->on(connect => sub {
			print "RTM (re)connected.\n" if ($self->{options}->{debug});
		});
	$ws_client->on(error => sub {
			my ($cli, $error) = @_;
			print STDERR 'error: '. $error;
		});
	$ws_client->connect;

	$self->{ws_client} = $ws_client;
	$self->{socket} = $socket;
}

sub disconnect {
	my $self = shift;
	$self->{ws_client}->disconnect;
	undef $self;
}

sub read {
	my $self = shift;
	my $data = '';
	while (my $line = readline $self->{socket}) {
		$data .= $line;
	}
	if ($data) {
		$self->{ws_client}->read($data);
		return $data =~ /.*hello.*/;
	}
}

sub write {
	my $self = shift;
	$self->{ws_client}->write(JSON::to_json({@_}));
}

sub _listen {
	my $self = shift;
	my ($buffer) = @_;
	my $buffer_obj;
	eval {
		$buffer_obj = JSON::from_json($buffer);
	};
	if ($@) {
		die "response is not json string. : $buffer";
	}
	if ($buffer_obj->{type} && $buffer_obj->{type} eq 'reconnect_url') {
		$self->{info}->{url} = $buffer_obj->{url};
	}

	my $response = Slack::RTM::Bot::Response->new(
		buffer => $buffer_obj,
		info   => $self->{info}
	);
ACTION: for my $action(@{$self->{actions}}){
		for my $key(keys %{$action->{events}}){
			my $regex = $action->{events}->{$key};
			if(!defined $response->{$key} || $response->{$key} !~ $regex){
				next ACTION;
			}
		}
		$action->{routine}->($response);
	}
};

1;