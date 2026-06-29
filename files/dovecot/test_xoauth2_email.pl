#!/usr/bin/perl

#NOTE: perl test_xoauth2_email.pl --to awesome@awesome.com --client_id kohaoidc --client_secret WJuA5vZ5WjMjFMDP4I0Eacmy2EmbiNzC --username service-account-kohaoidc --idp http://sso:8082/auth/realms/test/protocol/openid-connect/token

use strict;
use warnings;
use Getopt::Long;
use HTTP::Tiny;
use JSON;    #Auto-fallback to JSON::PP if JSON::XS not installed
use Net::SMTP;
use Authen::SASL;

my $recipient;
my $client_id;
my $client_password;
my $username;
my $idp;     #e.g. http://sso:8082/auth/realms/test/protocol/openid-connect/token
GetOptions(
    'to=s'            => \$recipient,
    'client_id=s'     => \$client_id,
    'client_secret=s' => \$client_password,
    'username=s'      => \$username,
    'idp=s'           => \$idp,
) or die("Error in command line arguments\n");
if ( !defined $recipient || !defined $client_id || !defined $client_password || !defined $username || !defined $idp ) {
    die "Usage: $0 --to <value> --client_id <id> --client_secret <pass> --username <user> --idp <idp>\n";
}
unless ( defined($recipient) && ( $recipient =~ /^[A-Z0-9_+]+([A-Z0-9_+.)*@(?:[A-Z0-9-]+\.)+[A-Z]{2,6}$/i ) ) {
    print STDERR "Usage: $0 email\@domain.tld\n";
    exit 1;
}
my $response = HTTP::Tiny->new->post_form(
    $idp,
    {
        grant_type    => "client_credentials",
        client_id     => $client_id,
        client_secret => $client_password,
        scope         => "openid profile",
    }
);
my $password = "";
if ( $response->{success} ) {
    my $data = decode_json( $response->{content} );
    if ( $data && $data->{access_token} ) {
        $password = $data->{access_token};
    }
} else {
    die $response->{status};
}
my $smtp = Net::SMTP->new(
    'dovecot',
    Port    => 31587,
    Timeout => 30,
    Debug   => 1,
);
die "Could not connect to server: $!" unless $smtp;

warn "USERNAME = $username";
warn "TOKEN = $password";

#Fake load since we've already embedded the dependency at bottom of script
$INC{'Authen/SASL/Perl/XOAUTH2.pm'} = 1;
my $sasl = Authen::SASL->new(
    mechanism => 'XOAUTH2',
    callback  => { user => $username, pass => $password }
);

#500 5.5.2 Line too long
#NOTE: If the SMTP response is over 1000 characters, Dovecot will reject it
$smtp->auth($sasl)
    or die "Failed to authenticate: $!";
$smtp->quit;


#NOTE: In lieu of Authen::SASL::Perl::XOAUTH2 being available on the system,
#we embed it directly here.

package Authen::SASL::Perl::XOAUTH2;

use strict;
use warnings;
use vars qw(@ISA);
use JSON::PP;

#@ISA     = qw(Authen::SASL::Perl);
use parent qw(Authen::SASL::Perl);

my %secflags = (
    noanonymous => 1,
);

sub _order { 1 }

sub _secflags {
    shift;
    scalar grep { $secflags{$_} } @_;
}

sub mechanism { 'XOAUTH2' }

sub client_start {
    my $self = shift;
    $self->{stage} = 0;

    # "user=" {User} "^Aauth=Bearer " {Access Token} "^A^A"
    # https://developers.google.com/gmail/imap/xoauth2-protocol#initial_client_response
    my $username = $self->_call('user');
    my $token    = $self->_call('pass'); # OAuth 2.0 access token
    my $auth_string = "user=$username\001auth=Bearer $token\001\001";
    return $auth_string
}

sub client_step {
    my ($self, $challenge) = @_;
    my $json = JSON::PP->new;
    my $payload = $json->decode( $challenge );
    $self->set_error( $payload );
    # Send dummy request on authentication failure according to rfc7628.
    # https://datatracker.ietf.org/doc/html/rfc7628#section-3.2.3
    return "\001";
}

1;

__END__

=head1 NAME

Authen::SASL::Perl::XOAUTH2 - XOAUTH2 Authentication class

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'XOAUTH2',
    callback  => {
      user => $user,
      pass => $access_token
    },
  );

=head1 DESCRIPTION

This module implements the client side of the XOAUTH2 SASL mechanism,
which is used for OAuth 2.0-based authentication.

=head2 CALLBACK

The callbacks used are:

=head3 Client

=over 4

=item user

The username to be used for authentication.

=item pass

The OAuth 2.0 access token to be used for authentication.

=back

=head1 SEE ALSO

L<Authen::SASL>,
L<Authen::SASL::Perl>

=head1 AUTHORS

Written by Aditya Garg and Julian Swagemakers.

=head1 COPYRIGHT

Copyright (c) 2025 Aditya Garg.

Copyright (c) 2025 Julian Swagemakers.

All rights reserved. This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.
=cut
