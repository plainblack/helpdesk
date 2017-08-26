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
use Test::Deep;
use HTML::Form;
use JSON;
use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;
use WebGUI::Asset::Wobject::HelpDesk;
use WebGUI::Asset::Ticket;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;
# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"HelpDesk Test"});
WebGUI::Test->addToCleanup($versionTag);

#----------------------------------------------------------------------------
# Tests

plan tests => 21;        # Increment this number for each test you create

#----------------------------------------------------------------------------
# put your tests here   ( 4 tests )

$session->user({userId => 3});

my $helpdesk = $node->addChild({
    className=>'WebGUI::Asset::Wobject::HelpDesk',
    title => 'test help desk',
         });
isa_ok($helpdesk,'WebGUI::Asset::Wobject::HelpDesk');
WebGUI::Test::addToCleanup($helpdesk);
is( $helpdesk->canEdit, 1, 'user can edit helpdesk');
is( $helpdesk->canPost, 1, 'user can post comments in helpdesk');
is( $helpdesk->canSubscribe, 1, 'user can subscribe to ticket update emails in helpdesk');

my $ticket = $helpdesk->addChild({
    className=>'WebGUI::Asset::Ticket',
    title => 'a test ticket',
});
isa_ok($ticket,'WebGUI::Asset::Ticket');
WebGUI::Test::addToCleanup($ticket);

$versionTag->commit();
$versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"HelpDesk Test"});
WebGUI::Test->addToCleanup($versionTag);

isa_ok( my $group = $helpdesk->createSubscriptionGroup, 'WebGUI::Group');
is( $helpdesk->getSubscriptionGroup->getId, $group->getId, 'getSubscriptionGroup matches createSubscriptionGroup');
WebGUI::Test::addToCleanup($group);

#----------------------------------------------------------------------------
# test meta fields   ( 4 tests )

    my $newId = $helpdesk->setCollateral("HelpDesk_metaField", "fieldId",{
                fieldId        => 'new',
                label          => 'MF1',
                dataType       => 'Date',
                searchable     => 0,
                showInList      => 0,
                required       => 0,
                possibleValues => '',
                defaultValues  => '',
                hoverHelp      => '',
        },1,1);

my $mf1 = $helpdesk->getHelpDeskMetaField($newId);
is($mf1->{label}, 'MF1', 'getHelpDeskMetaField tests OK');

$mf1 = $helpdesk->getHelpDeskMetaFieldByLabel('MF1');
is($mf1->{fieldId}, $newId, 'getHelpDeskMetaFieldByLabel tests OK');

my $mf = $helpdesk->getHelpDeskMetaFields({returnHashRef => 1});
isa_ok( $mf, 'HASH', 'getHelpDeskMetaFields');
is( scalar(keys %$mf), 1, "getHelpDeskMetaFields returns correct number of keys");
is_deeply( [keys %$mf], [ $newId ], "getHelpDeskMetaFields returns the correct key");

#----------------------

isa_ok( $helpdesk->i18n, 'WebGUI::International', 'i18n' );

$helpdesk->indexTickets; # no return value, TODO: can we test side effects?

$helpdesk->commit;
my $cron = WebGUI::Workflow::Cron->new($session, $helpdesk->get("getMailCronId"));
isa_ok( $cron, 'WebGUI::Workflow::Cron');
#WebGUI::Test::addToCleanup( $cron );  ---> does not work...
END { $cron->delete }  # should get removed when the previous gets fixed...

is( $helpdesk->isSubscribed, 0, 'isSubscribed returns 0');
is( $helpdesk->karmaIsEnabled, 0, 'karma is not enabled');

#----------------------

my $expect = {
        sort => "creationDate",
        startIndex => 1,
        totalRecords => 0,
        tickets => [],
        dir => 'DESC',
        recordsReturned => 25
    };

my $actual = from_json($helpdesk->www_getAllTickets);
cmp_deeply( $actual, $expect, 'test www_getAllTickets');

#----------------------

is( scalar( keys %{$helpdesk->getStatus}), 7, 'getStatus returns 7 items');
isa_ok( $helpdesk->getSortDirs, 'HASH', 'getSortDirs' );
isa_ok( $helpdesk->getSortOptions, 'HASH', 'getSortOptions' );

TODO: {
        local $TODO = "this test needs work";
# EMSSubmissionForm does something similar to this and it works

$session->form->setup_body({
    fieldId => 'new',
    dataType => 'Date',
    label => 'test metafield',
});
my $return_text = $helpdesk->www_editHelpDeskMetaFieldSave();

$versionTag->commit();
$versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"HelpDesk Test"});
WebGUI::Test->addToCleanup($versionTag);

$mf = $helpdesk->getHelpDeskMetaFields({returnHashRef => 1});
is( scalar(keys %$mf), 2, "successfully added a new meta field");

}

#----------------------------------------------------------------------------
# Cleanup
END {

}
#vim:ft=perl
