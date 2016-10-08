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
	$self->{channels} = &_parse_channels($args);
	$self->{groups}   = &_parse_groups($args);
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

sub _parse_channels {
	my $args = shift;
	my $channels = {};
	for my $channel (@{$args->{channels}}){
		$channels->{$channel->{id}} = $channel;
	}
	return $channels;
}

sub _parse_groups {
	my $args = shift;
	my $groups = {};
	while (my $group = shift @{$args->{groups}}){
		$groups->{$group->{id}} = $group;
	}
	return $groups;
}

sub _find_channel_or_group_id {
	my $self = shift;
	my ($name) = @_;
	return $self->_find_channel_id($name) ||
        $self->_find_group_id($name) ||
        die "There are no channels or groups of such name: $name";
}

sub _find_channel_id {
	my $self = shift;
	my ($name) = @_;
	my $channels = $self->{channels};
	for my $key (keys %{$channels}){
		if($name eq $channels->{$key}->{name}){
			return $channels->{$key}->{id};
		}
	}
	return undef;
}

sub _find_group_id {
	my $self = shift;
	my ($name) = @_;
	my $groups = $self->{groups};
	for my $key (keys %{$groups}){
		if($name eq $groups->{$key}->{name}){
			return $groups->{$key}->{id};
		}
	}
	return undef;
}

sub _find_channel_or_group_name {
	my $self = shift;
	my ($id) = @_;
    $self->_find_channel_name($id) ||
        $self->_find_group_name($id) ||
        die "There are no channels or groups of such id: $id";
}

sub _find_channel_name {
	my $self = shift;
	my ($id) = @_;
	my $channels = $self->{channels};
	return $channels->{$id}->{name} if $channels->{$id};
}

sub _find_group_name {
	my $self = shift;
	my ($id) = @_;
	my $groups = $self->{groups};
	return $groups->{$id}->{name} if $groups->{$id};
}

sub _find_user_name {
	my $self = shift;
	my ($id) = @_;
	my $users = $self->{users};
	$users->{$id} or die "There are no users of such id: $id";
	return $users->{$id}->{name};
}

1;