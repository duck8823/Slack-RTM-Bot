package Slack::RTM::Bot::Response;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $args = {@_};
	my $self = {%{$args->{buffer}}};
	$self->{user} = $args->{user};
	$self->{channel} = $args->{channel};
	return bless $self, $pkg;
}

1;