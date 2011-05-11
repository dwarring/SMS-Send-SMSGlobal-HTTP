#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::Send::AU::SMSGlobal' ) || print "Bail out!
";
}

diag( "Testing SMS::Send::AU::SMSGlobal $SMS::Send::AU::SMSGlobal::VERSION, Perl $], $^X" );
