#!perl

#
# send_sms.t was copied and adapted from SMS::Send::Clickatell
# t/01-construct-request.t with thanks to Brian McCauley.
#

use strict;
use warnings;

use Test::More tests => 15;
use Test::MockObject;
use Test::Exception;

use SMS::Send;

my $send;

lives_ok( sub {
    $send = SMS::Send->new( 'SMSGlobal::HTTP',
			    _user => "someone",
			    _password => "secret",
			    ##    __verbose => 1,
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
    my ($case,$expect_ok,@stati) = @_;
    @mock_responses = map { my ($code,$content) = @$_;
			    my $resp = HTTP::Response->new($code);
			    $resp->content($content);
			    $resp;
    } @stati;
    @requests = ();
    is(!!$send->send_sms(%message), !!$expect_ok, "send_sms() status $case");
    my %content = $requests[-1]->content =~ /\G(.*?)=(.*?)(?:&|$)/g;
    is_deeply(\%content,\%expected_content, "request content $case")
	if %expected_content;
    ok(!@mock_responses,"number of requests $case");
}

my $SENT = 1;

check_request("ok message, immediate delivery",$SENT,[200 => 'OK: 0; Sent queued message ID: 941596d028699601']);

$message{'_scheduledatetime'} = '2999-12-31 11:59:59';
$expected_content{scheduledatetime} = '2999-12-31+11%3A59%3A59';

check_request("ok message, delayed delivery",$SENT,[200 => 'SMSGLOBAL DELAY MSGID:49936728']);

delete $message{_from};
delete $expected_content{from};

check_request("invalid request",!$SENT,[200 => 'ERROR: Missing parameter: from']);

check_request("404 error",!$SENT,[404 => 'OK']);

