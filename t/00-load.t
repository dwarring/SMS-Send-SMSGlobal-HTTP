#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::Send::SMSGlobal' ) || print "Bail out!
";
}

diag( "Testing SMS::Send::SMSGlobal $SMS::Send::SMSGlobal::VERSION, Perl $], $^X" );
