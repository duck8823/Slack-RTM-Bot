package Slack::RTM::Bot::Information;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my ($args) = {@_};
	my $self = {
		@_,
	};
	$self->{users}    = &_parse_users($args);
	$self->{channels} = &_parse_conversations($args);
	return bless $self, $pkg;
}

sub _parse_users {
	my $args = shift;
	my $users = {};
	for my $user (@{$args->{users}}){
		$users->{$user->{id}} = $user;
	}
	return $users;
}

sub _parse_conversations {
	my $args = shift;
	my $conversations = {};
	for my $conversation (@{$args->{channels}}){
		$conversations->{$conversation->{id}} = $conversation;
	}
	return $conversations;
}

sub _find_conversation_id {
	my $self = shift;
	my ($name) = @_;
	my $conversations = $self->{channels};

	for my $key (keys %{$conversations}){
		if($name eq $conversations->{$key}->{name}){
			return $conversations->{$key}->{id};
		}
	}
	return undef;
}

sub _find_conversation_name {
	my $self = shift;
	my ($id) = @_;
	my $conversations = $self->{channels};
	return $conversations->{$id}->{name} if $conversations->{$id};
}

sub _find_user_name {
	my $self = shift;
	my ($id) = @_;
	my $users = $self->{users};
	return $users->{$id}->{name} if $users->{$id};
}

1;
