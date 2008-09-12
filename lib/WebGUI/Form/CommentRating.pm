package WebGUI::Form::CommentRating;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2008 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Form::RadioList';

=head1 NAME

Package WebGUI::Form::CommentRating

=head1 DESCRIPTION

Displays a comment rating field (unhappy to happy).

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Control::RadioList.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the super class for additional details.

=head3 additionalTerms

The following additional parameters have been added via this sub class.

=cut

sub definition {
    my $class = shift;
    my $session = shift;
    my $definition = shift || [];
    push(@{$definition}, {
        imagePath => {
			defaultValue=>"wobject/Bazaar/rating/"
		},
		imageExtension=>{
			defaultValue=>"png"
		},
		defaultRating=>{
			defaultValue=>3
		},
    });
    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the name of the form control.

=cut

sub getName {
    my ($class, $session) = @_;
    return 'Comment Rating';
}

#-------------------------------------------------------------------

=head2 getImage ( [rating] )

Creates the image based on the rating value passed in.  If no value is passed, the default rating is used

=cut

sub getImage {
    my $self   = shift;
    my $value  = shift;

    if ($value !~ m/^\d+$/ || $value < 1 || $value > 5) {
        $value = $self->get("defaultRating");
    }

    my $src = $self->session->url->extras($self->get("imagePath").$value.".".$self->get("imageExtension"));
    return qq{<img src="$src" style="vertical-align: middle;" alt="$value" title="$value" />}
}

#-------------------------------------------------------------------

=head2 getOptions ( )

Options are passed in for many list types. Those options can come in as a hash ref, or a \n separated string, or a key|value\n separated string. This method returns a hash ref regardless of what's passed in.

=cut

sub getOptions {
    my ($self) = @_;
    my %options = ();
    tie %options, 'Tie::IxHash';
    foreach my $value (1..5) {
        $options{$value} = $self->getImage($value);
    }
    return \%options;
}

#-------------------------------------------------------------------

=head2 getValue ( [ value ] )

Does some special processing.

=cut

sub getValue {
    my $self = shift;
    my $value = $self->SUPER::getValue(@_);

    if ($value !~ m/^\d+$/ || $value < 1 || $value > 5) {
        $value = $self->get("defaultRating");
    }

    return $value;
}

#-------------------------------------------------------------------

=head2 getValueAsHtml ( )

Formats as an icon.

=cut

sub getValueAsHtml {
    my $self = shift;
    my $value = $self->getValue;
    my $url = $self->session->url;
    return $self->getImage($value);
}


1;