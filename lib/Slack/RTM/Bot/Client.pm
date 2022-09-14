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

	my $res = $ua->request(POST 'https://slack.com/api/rtm.connect', [ token => $token ]);
	my $content;
	eval {
		$content = JSON::from_json($res->content);
	};
	if ($@) {
		die 'connect response fail:'.Dumper $res->content;
	}
	die 'connect response fail: '.$res->content unless ($content->{ok});

	$self->{info} = Slack::RTM::Bot::Information->new(%{$content});
	$res = $ua->request(POST 'https://slack.com/api/conversations.list ', [ token => $token ]);
	eval {
		$content = JSON::decode_json($res->content);
	};
	if ($@) {
		die 'connect response fail:'.Dumper $res->content;
	}
	die 'connect response fail: '.$res->content unless ($content->{ok});

	for my $im (@{$content->{channels}}) {
		$self->{info}->{channels}->{$im->{id}} = { %$im, name => '@'.$im->{name} };
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
	$self->{ws_client}->write(JSON::encode_json({@_}));
}

sub find_conversation_id {
	my $self = shift;
	my ($name) = @_;
	my $id = $self->{info}->_find_conversation_id($name);
	$id ||= $self->_refetch_conversation_id($name) or die "There are no conversations of such name: $name";
	return $id;
}

sub _refetch_conversation_id {
	my $self = shift;
	my ($name) = @_;
	$self->_refetch_conversations;
	return $self->{info}->_find_conversation_id($name);
}

sub find_conversation_name {
	my $self = shift;
	my ($id) = @_;
	my $name = $self->{info}->_find_conversation_name($id);
	$name ||= $self->_refetch_conversation_name($id) or warn "There are no conversations of such id: $id";
	$name ||= $id;
	return $name;
}

sub _refetch_conversation_name {
	my $self = shift;
	my ($id) = @_;
	$self->_refetch_conversations;
	return $self->{info}->_find_conversation_name($id);
}

sub _refetch_conversations {
	my $self = shift;
	my $res;
	eval {
		my $conversations = {};
		my $cursor = "";
		do {
			$res = $ua->request(GET "https://slack.com/api/conversations.list?types=public_channel,private_channel&token=$self->{token}&cursor=$cursor&limit=1000");
			my $args = JSON::from_json($res->content);
			for my $conversation (@{$args->{channels}}) {
				$conversations->{$conversation->{id}} = $conversation;
			}
			$cursor = $args->{response_metadata}->{next_cursor};
		} until ($cursor eq "");
		$self->{info}->{channels} = $conversations;
       };
       if ($@) {
	       die '_refetch_conversations response fail:'.Dumper $res->content;
       }
}

sub find_user_name {
	my $self = shift;
	my ($id) = @_;
	my $name = $self->{info}->_find_user_name($id);
	$name ||= $self->_refetch_user_name($id) or warn "There are no users of such id: $id";
	$name ||= $id;
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
	my $res;
	eval {
		my $users = {};
		my $cursor = "";
		do {
			$res = $ua->request(GET "https://slack.com/api/users.list?token=$self->{token}&cursor=$cursor");
			my $args = JSON::from_json($res->content);
			for my $user (@{$args->{members}}) {
				$users->{$user->{id}} = $user;
			}
			$cursor = $args->{response_metadata}->{next_cursor};
		} until ($cursor eq "");
		$self->{info}->{users} = $users;
       };
       if ($@) {
	       die '_refetch_users response fail:'.Dumper $res->content;
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
		warn "There are no users of such id: $buffer_obj->{user}" unless $user;
	}
	if ($buffer_obj->{channel} && !ref($buffer_obj->{channel})) {
		$channel = $self->find_conversation_name($buffer_obj->{channel});
		warn "There are no conversations of such id: $buffer_obj->{channel}" unless $channel;

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
