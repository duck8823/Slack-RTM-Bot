package Slack::RTM::Bot::Client;

use strict;
use warnings;

use JSON;
use Encode;
use Data::Dumper;

use HTTP::Request::Common qw(POST GET);
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

sub find_channel_or_group_id {
	my $self = shift;
	my ($name) = @_;
	my $id = $self->{info}->_find_channel_or_group_id($name);
	$id ||= $self->_refetch_channel_id($name);
	$id ||= $self->_refetch_group_id($name) or die "There are no channels or groups of such name: $name";
	return $id;
}

sub _refetch_channel_id {
	my $self = shift;
	my ($name) = @_;
	$self->_refetch_channels;
	return $self->{info}->_find_channel_or_group_id($name);
}

sub _refetch_group_id {
	my $self = shift;
	my ($name) = @_;
	$self->_refetch_groups;
	return $self->{info}->_find_channel_or_group_id($name);
}

sub find_channel_or_group_name {
	my $self = shift;
	my ($id) = @_;
	my $name = $self->{info}->_find_channel_or_group_name($id);
	$name ||= $self->_refetch_channel_name($id);
	$name ||= $self->_refetch_group_name($id) or die "There are no channels or groups of such id: $id";
	return $name;
}

sub _refetch_channel_name {
	my $self = shift;
	my ($id) = @_;
	$self->_refetch_channels;
	return $self->{info}->_find_channel_or_group_name($id);
}

sub _refetch_group_name {
	my $self = shift;
	my ($id) = @_;
	$self->_refetch_groups;
	return $self->{info}->_find_channel_or_group_name($id);
}

sub _refetch_channels {
	my $self = shift;
	my $res = $ua->request(GET "https://slack.com/api/channel.list?token=$self->{token}");
	eval {
		$self->{info}->{channels} = Slack::RTM::Bot::Information::_parse_channels(JSON::from_json($res->content));
	};
	if ($@) {
		die 'response fail:'.Dumper $res->content;
	}
}

sub _refetch_groups {
	my $self = shift;
	my $res = $ua->request(GET "https://slack.com/api/groups.list?token=$self->{token}");
	eval {
		$self->{info}->{groups} = Slack::RTM::Bot::Information::_parse_groups(JSON::from_json($res->content));
	};
	if ($@) {
		die 'response fail:'.Dumper $res->content;
	}
}

sub find_user_name {
	my $self = shift;
	my ($id) = @_;
	my $name = $self->{info}->_find_user_name($id);
	$name ||= $self->_refetch_user_name($id) or die "There are no users of such id: $id";
	return $name;
}

sub _refetch_user_id {
	my $self = shift;
	my ($name) = @_;
	$self->_refetch_users;
	return $self->{info}->_find_user_id($name);
}

sub _refetch_user_name {
	my $self = shift;
	my ($id) = @_;
	$self->_refetch_users;
	return $self->{info}->_find_user_name($id);
}

sub _refetch_users {
	my $self = shift;
	my $res = $ua->request(GET 'https://slack.com/api/users.list', [ token => $self->{token} ]);
	eval {
		$self->{info}->{users} = Slack::RTM::Bot::Information::_parse_users(JSON::from_json($res->content));
	};
	if ($@) {
		die 'response fail:'.Dumper $res->content;
	}
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

	my ($user, $channel);
	if ($buffer_obj->{user} && !ref($buffer_obj->{user})) {
		$user = $self->find_user_name($buffer_obj->{user});
		$user ||= $self->_refetch_user_name($buffer_obj->{user});
		die "There are no users of such id: $buffer_obj->{user}" unless $user;
	}
	if ($buffer_obj->{channel} && !ref($buffer_obj->{channel})) {
		$channel = $self->find_channel_or_group_name($buffer_obj->{channel});
		$channel ||= $self->_refetch_channel_name($buffer_obj->{channel});
		$channel ||= $self->_refetch_group_name($buffer_obj->{channel});
		die "There are no channels or groups of such id: $buffer_obj->{user}" unless $user;
	}
	my $response = Slack::RTM::Bot::Response->new(
		buffer  => $buffer_obj,
		user    => $user,
		channel => $channel
	);
ACTION: for my $action(@{$self->{actions}}){
		for my $key(keys %{$action->{events}}){
			my $regex = $action->{events}->{$key};
			if(!defined $response->{$key} || $response->{$key} !~ $regex){
				next ACTION;
			}
		}
		eval {
			$action->{routine}->($response);
		};
		if ($@) {
			warn $@;
			kill 9, @{$self->{pids}};
			exit(1);
		}
	}
};

1;