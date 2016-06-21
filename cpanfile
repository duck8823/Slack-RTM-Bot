requires 'Encode';
requires 'HTTP::Request::Common';
requires 'IO::Socket::SSL';
requires 'LWP::UserAgent';
requires 'Protocol::WebSocket::Client';
requires 'parent';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
};
