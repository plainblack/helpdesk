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

plan tests => 4;        # Increment this number for each test you create

#----------------------------------------------------------------------------
# put your tests here

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
# Cleanup
END {

}
#vim:ft=perl
