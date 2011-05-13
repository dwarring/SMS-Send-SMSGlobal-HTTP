package SMS::Send::SMSGlobal;

use warnings;
use strict;

use parent 'SMS::Send::Driver';
use HTTP::Request::Common qw(POST);

require LWP::UserAgent;

=head1 NAME

SMS::Send::SMSGlobal - SMS::Send SMSGlobal.com Driver

=head1 VERSION

Version 0.01_1

=cut

our $VERSION = '0.01_1';

=head2 SYNOPSIS

    use SMS::Send;

    my $sender = SMS::Send->new('SMSGlobal',
               _user      => 'my-username',
               _password  => 'my-password',
               _transport => 'http',          # 'https' (default), or 'http'
               _method => 'get',              # http method 'get' (default) or 'post'
               _verbose =>     1              # enable tracing
           );

    my $sent = $sender->send_sms(
        to        => '+61 4 8799 9999',       # the recipient phone number
        text      => "Hello, SMS world!",     # the text of the message to send
        _from     => '+6 1 4881 11111',       # optional from address per message (for email)
    );

=cut

=head1 DESCRIPTION

SMS::Send::SMSGlobal is a very bare-bones driver for L<SMS::Send> for
the SMS gateway at www.smsglobal.com via HTTP. It currently supports only
the most basic of functionality required by the author so he could use
SMS::Send.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $ua = LWP::UserAgent->new;

    my $transport = $args{_transport} || 'https';

    if ($transport eq 'https') {
	require Crypt::SSLeay;
    }
    else {
	die "unknown value for _transport $transport: expected 'http' or 'https'"
	    unless $transport eq 'http';
    }

    # Create the object
    my $self = bless {
	ua => $ua,
	verbose => $args{_verbose},
	transport => $transport,
	method => $args{_method},
	_defaults  => {
	    user =>  $args{_login} || $args{_user} || $args{_username},
	    password => $args{_password},
	    maxsplit => 3,
	    },
    }, $class;

    $self;
}

=cut

=head2 send_sms

=cut

sub send_sms {
    my $self = shift;
    my %message = @_;

    my %params = (
	%{ $self->{_defaults}},
	action => 'sendsms',	    
	to => delete $message{to},
	text => delete $message{text},
	);

    foreach (qw(user password from api maxsplit userfield scheduleddatetime)) {

	my $val = delete $message{ '_' . $_ };

	$params{ $_ } = $val
	    if defined $val;
    }

    if (my @_ignored_options = sort keys %message) {
	warn ref($self)
	    . "->send_sms: ignoring unsupported option(s): @_ignored_options"
    };

    for ($params{to}, $params{from}) {
	next unless defined;

	s{^\+}{};
	s{\s}{}g;
    }

    if ($self->{verbose}) {
	print "params:\n";
	foreach (sort keys %params) {
	    print "  $_: $params{$_}\n"
	}
    }

    my $transport = $self->{transport};
    my $method = $self->{method} || 'post';

    my $address = "$transport://smsglobal.com/http-api.php";
    print "Address : $address ($method)" if $self->{verbose};

    my $req =  ($method =~ m{get}i)
	? GET($address => [ %{ \%params } ])
	: POST($address => [ %{ \%params } ]);
    
    my $res = $self->{ua}->request($req);
	
    if ($self->{verbose} ) {
	print "Status: ",$res->status_line,"\n";
	print $res->headers_as_string,"\n",$res->content,"\n";
    }
	
    return $res->is_success;
}

=head1 AUTHOR

David Warrring, C<< <david.warring at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-send-au-smsglobal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-AU-SMSGlobal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::SMSGlobal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-SMSGlobal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-SMSGlobal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-SMSGlobal>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-SMSGlobal/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Warrring.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SMS::Send::SMSGlobal
