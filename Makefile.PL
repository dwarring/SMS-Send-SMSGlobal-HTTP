use inc::Module::Install;

name     'SMS-Send-SMSGlobal-HTTP';
all_from 'lib/SMS/Send/SMSGlobal/HTTP.pm';
author   q{David Warrring <david.warring@gmail.com>};
license  'perl';

requires (
    'LWP::UserAgent'        => 0,
    'SMS::Send::Driver'     => 0,
    'HTTP::Request::Common' => 0,
    'Class::Accessor'       => 0,
    'fields'                => 0,
    'parent'                => 0,
    'Crypt::SSLeay'         => 0,
    );

recommends (
    );

build_requires 'Test::More';

auto_install;

#
# Module::Install::Repository magic
#
auto_set_repository();

WriteAll;

