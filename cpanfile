requires 'Encode';
requires 'HTTP::Request::Common';
requires 'IO::Socket::SSL';
requires 'JSON';
requires 'Data::Dumper';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Protocol::WebSocket::Client';
requires 'perl', '5.008001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::More', '0.98';
};
