use inc::Module::Install;

name     'SMS-Send-SMSGlobal';
all_from 'lib/SMS/Send/SMSGlobal.pm';
author   q{David Warrring <david.warring@gmail.com>};
license  'perl';

requires (
    'LWP::UserAgent'        => 0,
    'SMS::Send::Driver'     => 0,
    'HTTP::Request::Common' => 0,
    );

recommends (
    'Crypt::SSLeay' => 0,
    );

build_requires 'Test::More';

auto_install;

#
# Module::Install::Repository magic
#
auto_set_repository();

WriteAll;

