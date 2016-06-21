package Slack::RTM::Bot::Response;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $args = {@_};
	my $self = {%{$args->{buffer}}};
	$self->{user} = $args->{info}->_find_user_name($self->{user}) if $self->{user};
	$self->{channel} = $args->{info}->_find_channel_name($self->{channel}) if $self->{channel};
	return bless $self, $pkg;
}

1;