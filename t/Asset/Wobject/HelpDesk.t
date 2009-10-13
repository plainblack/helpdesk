# vim:syntax=perl
#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#------------------------------------------------------------------

# This script tests the Help Desk and Ticket modules...
# 

use FindBin;
use strict;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;
# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"HelpDesk Test"});
WebGUI::Test->tagsToRollback($versionTag);

#----------------------------------------------------------------------------
# Tests

plan tests => 8;        # Increment this number for each test you create

#----------------------------------------------------------------------------
# put your tests here   ( 4 tests )

use_ok("WebGUI::Asset::Wobject::HelpDesk");
use_ok("WebGUI::Asset::Ticket");
my $helpdesk = $node->addChild({
    className=>'WebGUI::Asset::Wobject::HelpDesk',
    title => 'test help desk',
         });
#$versionTag->commit();
isa_ok($helpdesk,'WebGUI::Asset::Wobject::HelpDesk');

my $ticket = $helpdesk->addChild({
    className=>'WebGUI::Asset::Ticket',
    title => 'a test ticket',
});
isa_ok($ticket,'WebGUI::Asset::Ticket');

#----------------------------------------------------------------------------
# test meta fields   ( 3 tests )

my $mf = $helpdesk->getHelpDeskMetaFields({returnHashRef => 1});
isa_ok( $mf, 'HASH', "getHelpDeskMetaFields returns a HASH ref");
is( scalar(keys %$mf), 0, "getHelpDeskMetaFields returns correct number of keys");

TODO: {
        local $TODO = "need to perform login for this test";

# TODO $session->user({userId => 3});

$session->form->setup_body({
    fieldId => 'new',
    dataType => 'Date',
    label => 'test metafield',
});
my $return_text = $helpdesk->www_editHelpDeskMetaFieldSave();
#print $return_text;
unlike( $return_text, '/error/i', "return from meta field save has no errors");
$mf = $helpdesk->getHelpDeskMetaFields({returnHashRef => 1});
is( scalar(keys %$mf), 1, "successfully added a new meta field");

}

#----------------------------------------------------------------------------
# Cleanup
END {

}
#vim:ft=perl
