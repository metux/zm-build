# SPDX-License-Identifier: GPL-2.0-only

package Zimbra::SOAP::Soap12;

use strict;
use warnings;

use XML::Parser;
use Zimbra::SOAP::XmlElement;

#use overload '""' => \&to_string;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 1.00;
    @ISA         = qw(Exporter Zimbra::SOAP::Soap);
    @EXPORT      = qw();
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw();
}

our @EXPORT_OK;

our $NS = "http://www.w3.org/2003/05/soap-envelope";

sub new {
    my $type = shift;
    my $self = {};
    bless $self, $type;
    return $self;
}

#
# given a XmlElement, wrap it in a SOAP envelope and return the envelope
#

sub soapEnvelope {
    my $self = shift;
    my $e = shift;
    my $context = shift;
    my $env = new Zimbra::SOAP::XmlElement("Envelope", $NS);
    if ($context) {
	    my $header= new Zimbra::SOAP::XmlElement("Header", $NS);
	    $header->add_child($context);
	    $env->add_child($header);
    }
    my $body = new Zimbra::SOAP::XmlElement("Body", $NS);
    $body->add_child($e);
    $env->add_child($body);
    return $env;
}

sub getContentType() {
    return "application/soap+xml; charset=utf-8";
}

#
# Return the namespace String
#

sub getNamespace {
    return $NS;
}

#
# return the first child in the soap body
#

sub getElement {
    my ($self, $e) = @_;

    die "getElement was not passed a Soap Envelope" unless
	($e->name() eq 'Envelope') && ($e->ns() eq $NS);

    my $body = $e->find_child('Body');
    die "getElement unable to find Soap Body" unless defined $body;

    return $body->child(0);
}

#
# Returns true if this element represents a SOAP fault
#

sub isFault {
    my ($self, $e) = @_;
    return 
	($e->name() eq 'Fault') &&
	($e->ns() eq $NS);
}

#
# Whether or not to include a HTTP SOAPActionHeader. (Gag)
#

sub hasSOAPActionHeader {
    return 0;
}

#
# returns the version as a string (e.g, "1.1" or "1.2")
#

sub getVersion {
    return "1.2";
}

1;
