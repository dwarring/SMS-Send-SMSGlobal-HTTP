#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 14;
use Test::NoWarnings;
use Test::Exception;

use SMS::Send::SMSGlobal::HTTP;

my $obj;
lives_ok( sub {
    $obj = SMS::Send::SMSGlobal::HTTP->new(
	_user      => 'my-username',
	_password  => 'my-password',
	__verbose =>  1
	);
	  },
	  "SMS::Send::SMSGlobal::HTTP->new(...) - lives"
    );

isa_ok( $obj => "SMS::Send::SMSGlobal::HTTP");
die "can't continue without object" unless $obj;

can_ok($obj => qw(send_sms action text to _user _password _from _maxsplit
                  _scheduledatetime _api _userfield __transport __verbose
                  __ua __address));

lives_ok(sub {$obj->{text} = 'sample message'}, 'setting via hash - lives');
is($obj->text, 'sample message', 'getter 1');
is($obj->get('text'), 'sample message', 'getter 2');

lives_ok(sub {$obj->text('message 2')});
is($obj->text, 'message 2');

lives_ok(sub {$obj->set(text => 'message 3')} );
is($obj->text, 'message 3');

dies_ok(sub {$obj->crud} );
dies_ok(sub {$obj->{crud} = "shouldn't work"} );
dies_ok(sub {$obj->set(crud => "shouldn't work either")} );

1;

