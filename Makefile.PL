use inc::Module::Install;

name     'SMS-Send-AU-SMSGlobal';
all_from 'lib/SMS/Send/AU/SMSGlobal.pm';
author   q{David Warrring <david.warring@gmail.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

