package SMS::Send::SMSGlobal::HTTP;

use warnings;
use strict;

use parent 'SMS::Send::Driver', 'Class::Accessor';
use HTTP::Request::Common qw(POST);

require LWP::UserAgent;

sub __fields {
    return qw(action text to _user _password _from _maxsplit _scheduledatetime
              _api _userfield __transport __verbose __ua __address)
};

use fields __PACKAGE__->__fields;
__PACKAGE__->mk_accessors( __PACKAGE__->__fields );

=head1 NAME

SMS::Send::SMSGlobal::HTTP - SMS::Send SMSGlobal.com Driver

=head1 VERSION

VERSION 0.02

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

SMS::Send::SMSGlobal::HTTP is a simple driver for L<SMS::Send> for sending
messages via www.smsglobal.com using the HTTP/HTTPS CGI gateway.

=head1 SUBROUTINES/METHODS

=head2 new

    use SMS::Send;

    my $sender = SMS::Send->new('SMSGlobal::HTTP',
               _user      => 'my-username',
               _password  => 'my-password',
               __verbose =>  1
           );

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Create the object
    my $self = fields::new ($class);

    #
    # Allow comman _user and _password aliases; just to ease interchange
    # with other sms drivers
    #

    $self->{_user} = delete($args{_user})
	|| delete($args{_username})
	|| delete($args{_login});

    $self->{_password} = delete $args{_pass}
	|| delete $args{_password};

    foreach (sort keys %args) {
	$self->{$_} = $args{$_};
    }

    $self->{_maxsplit} ||= 3;

    $self->{__ua} ||= LWP::UserAgent->new;

    return $self;
}

=head2 send_sms

    my $sent = $sender->send_sms(
        to        => '+61 4 8799 9999',
        text      => 'Go to the window!',
        _from     => '+61 4 8811 1111',
        _scheduledtime => DateTime
                             ->now(time_zone => 'Australia/Melbourne')
                             ->add(minutes => 5)
    );

=head3 HTTP Options

=over 4

=item C<to>

The recipient number, formatted as +<CountryCode><LocalNumber>

=item C<text>

The text of the message. Note that that longer messages will
be split sent in chunks of 160 characters. You may also need to increase
C<_maxsplit> to send longer messages.

=item C<_from>

Sender's mobile number. Where to send replies.

=item C<_maxsplit> (default 3)

The maximum number of 160 character transmisson chunks. You may need to
increase this to send longer messages.

Note: Each chunk is metered as a separate message.

=item C<_scheduledtime>

Lets you delay sending of messages. This can be either (a) a string formatted
as "yyyy-mm-dd hh:mm:ss" or (b) a date/time object that support C<ymd> and
C<hms> methods. For example L<DateTime> or L<Time::Piece> objects.

Note: You date times need to to be specified in the same timezone as set in
your SMSGlobal account preferences.

=back

=head3 HTTP-2WAY Options

Some extra options, as described in L<http://www.smsglobal.com/docs/HTTP-2WAY.pdf>:

=over 4

=item C<_api>

enables 2-way message (default: 1 enabled)

=item C<_userfield>

custom field to store internal IDs or other information (Maximum of
255 characters)

=back

=head3 Internal Options

=over 4

=item C<__verbose>

enable tracing

=item C<__transport>

Transport to use: 'https' (default) or 'http'.

'https' is recommended, however you'll need to have either L<Crypt::SSLeay> or
L<IO::Socket::SSL>. More information at
<http://search.cpan.org/dist/libwww-perl/README.SSL>.

If neither of these are available on you platform, you can set your transport
to C<http>.

=item C<__address> 

SMSGlobal gateway address (default: 'http://smsglobal.com/http-api.php');

=back

=cut

sub send_sms {
    my $self = shift;
    my %opt = @_;

    use Carp; local ($SIG{__DIE__}) = \&Carp::cluck;

    my $msg = ref($self)->new( %$self, %opt );

    my %http_params = (
	action => 'sendsms',
	);

    foreach (sort keys %$msg) {
	next if m{^__};

	if (defined (my $val = $msg->{$_}) ) {
	    (my $key = $_) =~ s{^_}{};
	    $http_params{$key} = $val;
	}
    }

    if (ref $http_params{scheduledatetime} ) {
	#
	# stringify objects that support ymd & hms methods
	#
	for ( $http_params{scheduledatetime} ) {
	    $_ = $_->ymd('-') .' '.$_->hms(':')
		if (eval{
		    local $SIG{__DIE__};
		    $_->can('ymd') && $_->can('hms')
		    })
	}
    }

    for (qw(to from)) {
	#
	# tidy up from and to numbers
	#
	next unless defined $http_params{$_};

	$http_params{$_} =~ s{^\+}{}
    }

    if ($msg->__verbose) {
	print "http params:\n";
	foreach (sort keys %http_params) {
	    print "  $_: $http_params{$_}\n"
	}
    }

    my $address = $msg->__address || 'http://smsglobal.com/http-api.php';
    my $transport = $msg->__transport || 'https';

    if ($transport eq 'http') {
	$address =~ s{^https:}{http:};
    }
    else {
	$address =~ s{^http:}{https:};
    }

    print "Address : $address" if $msg->__verbose;

    my $req = POST($address => [ %{ \%http_params } ]);

    my $res = eval {
	local $SIG{__DIE__};
	$msg->__ua->request($req);
    };

    warn $@ if $@;

    if ($msg->__verbose ) {
	
	print "**Status**\n",$res->status_line,"\n";
	print "**Headers**\n",$res->headers_as_string,"\n";
	print "**Content**\n",$res->content,"\n";
    }

    my $success = $res->is_success
	&& $res->content =~ m{^(OK|SMSGLOBAL DELAY)};
	
    return $success;
}

=head1 AUTHOR

David Warrring, C<< <david.warring at gmail.com> >>

=head1 BUGS AND LIMITATIONS

This module only attempts to implement the frugal HTTP/S commands as described
in L<http://www.smsglobal.com/docs/HTTP-2WAY.pdf> and L<http://www.smsglobal.com/docs/HTTP-2WAY.pdf>.

There are other API's available (L<http://www.smsglobal.com/en-au/technology/developers.php>). Among the more fully featured
is the SOAP interface (L<http://www.smsglobal.com/docs/SOAP.pdf>).

Please report any bugs or feature requests to C<bug-sms-send-au-smsglobal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-SMSGlobal-HTTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::SMSGlobal::HTTP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-SMSGlobal-HTTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-SMSGlobal-HTTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-SMSGlobal-HTTP>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-SMSGlobal-HTTP/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Warring.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of SMS::Send::SMSGlobal
