#!perl

#
# send_sms.t was copied and adapted from SMS::Send::Clickatell
# t/01-construct-request.t with thanks to Brian McCauley.
#

use strict;
use warnings;

use Test::More tests => 27;
use Test::MockObject;
use Test::Exception;

use SMS::Send;

my $send;

lives_ok( sub {
    $send = SMS::Send->new( 'SMSGlobal::HTTP',
			    _user => "someone",
			    _password => "secret",
##			        __verbose => 1,
	)}, "SMS::Send->new('SMSGlobal::HTTP', ...) - lives");

isa_ok($send,'SMS::Send');

# Let's not send any real SMS!
my $mock_ua = Test::MockObject->new;

my (@requests,@mock_responses);

$mock_ua->mock( 
    request => sub {
	shift;
	push @requests => shift;
	shift @mock_responses or die;
    } );

{
    # Ugly but we need to mung the User Agent inside the driver inside the
    # object
    my $driver = $send->{OBJECT};

    isa_ok($driver,'SMS::Send::SMSGlobal::HTTP');
    $driver->{__ua} = $mock_ua;
}

my %message = (
    text => 'Hi there',
    # From Ofcom's Telephone Numbers for drama purposes (TV, Radio etc)
    to   => '+447700900999',
    _from => '+614444444444',
    );   

my %expected_content = (
    'action' => 'sendsms',
    'password' => 'secret',
    'to' => '447700900999',
    'from' => '614444444444',
    'text' => 'Hi+there',
    'user' => 'someone',
    'maxsplit' => '3'
    );

sub check_request {
    my ($case, $expect_ok, @stati) = @_;

    @mock_responses = map {
	my ($code,$content) = @$_;
	my $resp = HTTP::Response->new($code);
	$resp->content($content);
	$resp;
    } @stati;

    @requests = ();

    is(!!$send->send_sms(%message), !!$expect_ok, "send_sms() status $case");

    my $request = $requests[-1]
	or die "no request - unable to continue";

    my %content = $request->content =~ /\G(.*?)=(.*?)(?:&|$)/g;

    is_deeply(\%content,\%expected_content, "request content $case")
	if %expected_content;

    ok(!@mock_responses,"number of requests $case");

    return $request;
}

my $SENT = 1;

## basic requests ##

check_request("ok message, immediate delivery", $SENT, [200 => 'OK: 0; Sent queued message ID: 941596d028699601']);

# add in 2way fields

my $request;

do {
    local ( $message{_api} ) = 1;
    local ( $message{_userfield} ) = 'testing-1-2-3';

    local ( $expected_content{api} ) = 1;
    local ( $expected_content{userfield} ) = 'testing-1-2-3';

    $request = check_request("ok message with defaults, http", $SENT, [200 => 'OK: 0; Sent queued message ID: 941596d028699601']);
    is($request->method, 'POST', 'Default method is post');
    like($request->url, qr/^http:/, 'Default transport is http');
};

do {
    local( $message{__transport} ) = 'https';
    $request = check_request("ok message, transport https", $SENT, [200 => 'OK: 0; Sent queued message ID: 941596d028699601']);
    like($request->url, qr/^https:/, 'transport set to https');
};

## delayed messages

do {

    local ( $message{'_scheduledatetime'} );
    local ( $expected_content{scheduledatetime} );

    ## date strings

    $message{'_scheduledatetime'} = '2999-12-31 11:59:59';
    $expected_content{scheduledatetime} = '2999-12-31+11%3A59%3A59';

    check_request("ok message, scheduledatetime (string)", $SENT, [200 => 'SMSGLOBAL DELAY MSGID:49936728']);
    my $mock_dt = Test::MockObject->new;

    ## date objects

    $mock_dt->mock( 
	ymd => sub {
	    my $self = shift;
	    my $sep = shift;
	    join( $sep, qw(2061 10 21) );
	}
	);
    $mock_dt->mock(
	hms => sub {
	    my $self = shift;
	    my $sep = shift;
	    join( $sep, qw(09 05 17) );
	},
	);

    $message{'_scheduledatetime'} = $mock_dt;
    $expected_content{scheduledatetime} = '2061-10-21+09%3A05%3A17';

    check_request("ok message, scheduledatetime (object)", $SENT, [200 => 'SMSGLOBAL DELAY MSGID:49936728']);

};

delete $message{_from};
delete $expected_content{from};

check_request("invalid request", !$SENT, [200 => 'ERROR: Missing parameter: from']);

check_request("404 error",!$SENT,[404 => 'OK']);
