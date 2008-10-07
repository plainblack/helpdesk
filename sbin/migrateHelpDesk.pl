#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

our ($webguiRoot);

BEGIN { 
	$webguiRoot = "..";
	unshift (@INC, $webguiRoot."/lib"); 
}


$| = 1;

use Getopt::Long;
use strict;
use WebGUI::Asset;
use WebGUI::HTML;
use WebGUI::Session;
use WebGUI::Storage;
use WebGUI::Utility;
use JSON;
use Tie::IxHash;
use WebGUI::VersionTag;
use Data::Dumper;

my $configFile;
my $help;
my $quiet;
my $test;

GetOptions(
	'configFile=s' =>\$configFile,
    'help'         =>\$help,
    'quiet'        =>\$quiet,
    'test'         => \$test,
);


if ($help || $configFile eq ""){
        print <<STOP;


Usage: perl $0 --configfile=<webguiConfig>

    --configFile      WebGUI config file.

Options:

    --help         Display this help message and exit.

	--quiet        Disable output unless there's an error.

    --test         Enable test mode which will only migrate the last 90 days worth of posts and won't purge the original collaboration system

STOP
	exit;
	
}

print "Starting..." unless ($quiet);
my $session = WebGUI::Session->open($webguiRoot,$configFile);
my $db      = $session->db;

$session->user({userId=>3});

print "OK\n" unless ($quiet);

#Set the name of the working version tag.
my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name => 'Import Tickets into Help Desk'});

###############################################
#       IMPORT DATA
###############################################

#### Migrating collaboraiton systems ####
print "\tMigrating ..." unless ($quiet);

tie my %severities, "Tie::IxHash";
%severities = (
    'Cosmetic (misspelling, formatting problems)'   => "cosmetic",
    'Minor (annoying, but not harmful)'             => "minor",
    'Critical (mostly not working)'                 => "critical",
    "Fatal (can't continue until this is resolved)" => "fatal",
);

tie my %bugreports, "Tie::IxHash";
%bugreports = (
    "WebGUI Stable"      => "stable",
    "WebGUI Beta"        => "beta",
    "WebGUI Help"        => "help",
    "WebGUI Translation" => "translation",
    "WebGUI Books"       => "books",
    "WRE"                => "wre",
    "plainblack.com"     => "plainblack",
    "webgui.org"         => "webgui",
);

tie my %alumnibugs, "Tie::IxHash";
%alumnibugs = (
    "Not Sure"               =>"not_sure",
    "Alumni News"            =>"alumni_news",
    "Career Development"     =>"career_development",
    "Contact Info"           =>"contact_info",
    "Country Manager"        =>"country_manager",
    "Community Manager"      =>"community_manager",
    "Create Guest Account"   =>"create_guest_account",
    "Documentation"          =>"documentation",
    "Events Calendar"        =>"events_calendar",
    "Find Fellow Alumni"     =>"find_fellow_alumni",
    "Global History"         =>"global_history",
    "Grant Opportunities"    =>"grant_opportunities",
    "Interests Manager"      =>"interests_manager",
    "Mass Mail"              =>"mass_mail",
    "Photo Gallery"          =>"photo_gallery",
    "Program Agency Manager" =>"program_agency_manager",
    "Program Manager"        =>"program_manager",
    "Q&A Live"               =>"qa_live",
    "Registration"           =>"registration",
    "Region Manager"         =>"region_manager",
    "Site Design"            =>"site_design",
    "Update Your Profile"    =>"update_your_profile",
    "User Manager"           =>"user_manager",
    "Other"                  =>"other",
);

my $collabs = {
    "ybiC9afs4PE3F3-PUJ8yvA" => {
        userDefined1 => {
            label          => "Severity",
            dataType       => "SelectBox",
            possibleValues => "cosmetic|Cosmetic (misspelling, formatting problems)\r\nminor|Minor (annoying, but not harmful)\r\ncritical|Critical (mostly not working)\r\nfatal|Fatal (can\'t continue until this is resolved)",
            valuesMap      => \%severities
        },
        userDefined2 => {
            label          => "WebGUI Version",
            dataType       => "Text",
        },
        userDefined3 => {
            label          => "WRE Version",
            dataType       => "Text"
        },
        userDefined4 => {
            label          => "Operating System",
            dataType       => "Text"
        },        
    },
    "fBchvnfEp1zn8dTxr_-CAw" => {
        userDefined1 => {
            label          => "Severity",
            dataType       => "SelectBox",
            possibleValues => "cosmetic|Cosmetic (misspelling, formatting problems)\r\nminor|Minor (annoying, but not harmful)\r\ncritical|Critical (mostly not working)\r\nfatal|Fatal (can\'t continue until this is resolved)",
            valuesMap      => \%severities
        },
        userDefined2 => {
            label          => "What's the bug in?",
            dataType       => "SelectBox",
            possibleValues => "stable|WebGUI Stable\r\nbeta|WebGUI Beta\r\nhelp|WebGUI Help\r\ntranslation|WebGUI Translation\r\nbooks|WebGUI Books\r\nwre|WRE\r\nplainblack|plainblack.com\r\nwebgui|webgui.org",
            valuesMap      => \%bugreports
        },
        userDefined3 => {
            label          => "WebGUI / WRE Version",
            dataType       => "Text"
        },
    },
    #"gjWvDY8oNwaXx37Sx3y_tg" => {
    #     userDefined2 => {
    #        label          => "What to improve?",
    #        dataType       => "SelectBox",
    #        possibleValues => "stable|WebGUI Stable\r\nbeta|WebGUI Beta\r\nhelp|WebGUI Help\r\ntranslation|WebGUI Translation\r\nbooks|WebGUI Books\r\nwre|WRE\r\nplainblack|plainblack.com\r\nwebgui|webgui.org",
    #        valuesMap      => \%bugreports
    #    },
    #},
    #"N1-BkACXoerXrWzl9Uc3BQ" => {
    #    userDefined1 => {
    #        label          => "Severity",
    #        dataType       => "SelectBox",
    #        possibleValues => "cosmetic|Cosmetic (misspelling, formatting problems)\r\nminor|Minor (annoying, but not harmful)\r\ncritical|Critical (mostly not working)\r\nfatal|Fatal (can\'t continue until this is resolved)",
    #        valuesMap      => \%severities
    #    },
    #    userDefined2 => {
    #        label          => "What's the bug in?",
    #        dataType       => "SelectBox",
    #        possibleValues => "stable|WebGUI Stable\r\nbeta|WebGUI Beta\r\nhelp|WebGUI Help\r\ntranslation|WebGUI Translation\r\nbooks|WebGUI Books\r\nwre|WRE\r\nplainblack|plainblack.com\r\nwebgui|webgui.org",
    #        valuesMap      => \%bugreports
    #    },
    #    userDefined3 => {
    #        label          => "WebGUI / WRE Version",
    #        dataType       => "Text"
    #    },
    #},
    #"GZ_etc22H0GYXp10z2Zlww" => {
    #    userDefined1 => {
    #        label          => "Severity",
    #        dataType       => "SelectBox",
    #        possibleValues => "cosmetic|Cosmetic (misspelling, formatting problems)\r\nminor|Minor (annoying, but not harmful)\r\ncritical|Critical (mostly not working)\r\nfatal|Fatal (can\'t continue until this is resolved)",
    #        valuesMap      => \%severities
    #    },
    #    userDefined2 => {
    #        label          => "What's the bug in?",
    #        dataType       => "SelectBox",
    #        possibleValues => "not_sure|Not Sure\r\nalumni_news|Alumni News\r\ncareer_development|Career Development\r\ncontact_info|Contact Info\r\ncountry_manager|Country Manager\r\ncommunity_manager|Community Manager\r\ncreate_guest_account|Create Guest Account\r\ndocumentation|Documentation\r\nevents_calendar|Events Calendar\r\nfind_fellow_alumni|Find Fellow Alumni\r\nglobal_history|Global History\r\ngrant_opportunities|Grant Opportunities\r\ninterests_manager|Interests Manager\r\nmass_mail|Mass Mail\r\nphoto_gallery|Photo Gallery\r\nprogram_agency_manager|Program Agency Manager\r\nprogram_manager|Program Manager\r\nqa_live|Q&A Live\r\nregistration|Registration\r\nregion_manager|Region Manager\r\nsite_design|Site Design\r\nupdate_your_profile|Update Your Profile\r\nuser_manager|User Manager\r\nother|Other",
    #        valuesMap      => \%alumnibugs
    #    },
    #},
    #"VjPPoL1wpAKGhx1pIVL44w" => {
    #    userDefined1 => {
    #        label          => "Severity",
    #        dataType       => "SelectBox",
    #        possibleValues => "cosmetic|Cosmetic (misspelling, formatting problems)\r\nminor|Minor (annoying, but not harmful)\r\ncritical|Critical (mostly not working)\r\nfatal|Fatal (can\'t continue until this is resolved)",
    #        valuesMap      => \%severities
    #    },
    #    userDefined2 => {
    #        label          => "What's the bug in?",
    #        dataType       => "SelectBox",
    #        possibleValues => "not_sure|Not Sure\r\nalumni_news|Alumni News\r\ncareer_development|Career Development\r\ncontact_info|Contact Info\r\ncountry_manager|Country Manager\r\ncommunity_manager|Community Manager\r\ncreate_guest_account|Create Guest Account\r\ndocumentation|Documentation\r\nevents_calendar|Events Calendar\r\nfind_fellow_alumni|Find Fellow Alumni\r\nglobal_history|Global History\r\ngrant_opportunities|Grant Opportunities\r\ninterests_manager|Interests Manager\r\nmass_mail|Mass Mail\r\nphoto_gallery|Photo Gallery\r\nprogram_agency_manager|Program Agency Manager\r\nprogram_manager|Program Manager\r\nqa_live|Q&A Live\r\nregistration|Registration\r\nregion_manager|Region Manager\r\nsite_design|Site Design\r\nupdate_your_profile|Update Your Profile\r\nuser_manager|User Manager\r\nother|Other",
    #        valuesMap      => \%alumnibugs
    #    },
    #},
};

foreach my $collabId (keys %{$collabs}) {
    my $collab = WebGUI::Asset->newByDynamicClass($session,$collabId);

    my $parent = $collab->getParent;   #Page the collab system is on

    my $karmaEnabled = ($collab->get("karmaPerPost") > 0);

    #Get the url of the thread so we can reuse it.
    my $collabUrl      = $collab->getUrl;
    #Change the url of the thread so we can reuse it
    $collab->update({ url=>"helpdesk-tmp-url" });

    my $st = $db->read("select revisionDate from assetData where assetId=? and revisionDate<>?",[$collabId, $collab->get("revisionDate")]);
    while (my ($version) = $st->array) {
        my $old = WebGUI::Asset->new($session, $collabId, $collab->get("className"), $version);
        $old->purgeRevision if defined $old;
    }

    #Add a help desk to the page
    my $props = {
        className                          => "WebGUI::Asset::Wobject::HelpDesk",
        title                              => $collab->get("title"),
        menuTitle                          => $collab->get("menuTitle"),
        url                                => $collabUrl,
        ownerUserId                        => $collab->get("ownerUserId"),
        groupIdView                        => $collab->get("groupIdView"),
        groupIdEdit                        => $collab->get("groupIdEdit"),
        synopsis                           => $collab->get("synopsis"),
        newWindow                          => $collab->get("newWindow"),
        isHidden                           => $collab->get("isHidden"),
        isPackage                          => $collab->get("isPackage"),
        encryptPage                        => $collab->get("encryptPage"),
        extraHeadTags                      => $collab->get("extraHeadTags"),
        isExportable                       => $collab->get("isExportable"),
        displayTitle                       => $collab->get("displayTitle"),
        description                        => $collab->get("description"),
        styleTemplateId                    => $collab->get("styleTemplateId"),
        printableStyleTemplateId           => $collab->get("printableStyleTemplateId"),
        viewTemplateId                     => "HELPDESK00000000000001",
        viewMyTemplateId                   => "HELPDESK00000000000002",
        viewAllTemplateId                  => "HELPDESK00000000000003",
        searchTemplateId                   => "HELPDESK00000000000004",
        manageMetaTemplateId               => "HELPDESK00000000000005",
        editMetaFieldTemplateId            => "HELPDESK00000000000006",
        notificationTemplateId             => "HELPDESK00000000000007",
        editTicketTemplateId               => "TICKET0000000000000001",
        viewTicketTemplateId               => "TICKET0000000000000002",
        viewTicketRelatedFilesTemplateId   => "TICKET0000000000000003",
        viewTicketUserListTemplateId       => "TICKET0000000000000004",
        viewTicketCommentsTemplateId       => "TICKET0000000000000005",
        viewTicketHistoryTemplateId        => "TICKET0000000000000006",
        richEditIdPost                     => $collab->get("richEditor"),
        approvalWorkflow                   => $collab->get("approvalWorkflow"),
        groupToPost                        => $collab->get("postGroupId"),
        groupToChangeStatus                => $collab->get("groupToEditPost"),
        karmaEnabled                       => $karmaEnabled,
        karmaPerPost                       => $collab->get("karmaPerPost"),
        karmaToClose                       => $collab->get("karmaPerPost"),
        defaultKarmaScale                  => $collab->get("defaultKarmaScale"),
        sortColumn                         => "creationDate",
        sortOrder                          => "DESC",
        mailServer                         => $collab->get("mailServer"),
        mailAccount                        => $collab->get("mailAccount"),
        mailPassword                       => $collab->get("mailPassword"),
        mailAddress                        => $collab->get("mailAddress"),
        mailPrefix                         => $collab->get("mailPrefix"),
        getMail                            => $collab->get("getMail"),
        getMailInterval                    => $collab->get("getMailInterval"),
        autoSubscribeToTicket              => $collab->get("autoSubscribeToTicket"),
        requireSubscriptionForEmailPosting => $collab->get("requireSubscriptionForEmailPosting"),
        closeTicketsAfter                  => 1209600
    };
    #print Dumper($props)."\n\n";

    my $helpDesk  = $parent->addChild($props,undef,undef,{ skipAutoCommitWorkflows=>1 });
    
    #Skip notifications
    $helpDesk->setSkipNotification;

    #Create the subscription group and migrate all the users
    my $hdSubGroup       = $helpDesk->getSubscriptionGroup;
    my $collabSubGroupId = $collab->get('subscriptionGroupId');
    if ($collabSubGroupId) {
	    my $users = WebGUI::Group->new($session,$collabSubGroupId)->getUsers(1);
        $hdSubGroup->addUsers($users);
    }

    #Create the meta fields
    my $metaFields = $collabs->{$collabId};
    foreach my $id (keys %{$metaFields}) {
        my %hash = %{$metaFields->{$id}};
        $hash{'fieldId'   } = "new";
        $hash{'searchable'} = 0;
        $hash{'required'  } = 0;
        $hash{'assetId'   } = $helpDesk->getId;
        delete $hash{'valuesMap'};
        my $fieldId = $db->setRow("HelpDesk_metaField","fieldId",\%hash);
        #print Dumper(\%hash)."\n\n";
        #Set the field id in the hash
        $collabs->{$collabId}->{$id}->{fieldId} = $fieldId;
    }

    my $whereClause = undef;
    if($test) {
        $whereClause = "asset.creationDate > ".(time() - (60 * 60 * 24 * 90));
    }
    
    #Add the Tickets to the help desk
    my $threads = $collab->getLineage(["children"],{
        returnObjects      => 1,
        includeOnlyClasses => ["WebGUI::Asset::Post::Thread"],
        orderByClause      => "asset.creationDate asc",
        statusToInclude    => ["approved","archived"],
        includeArchived    => 1,
        whereClause        => $whereClause,
    });
    
    my $totalThreads = scalar(@{$threads});
    print "Total Threads To Transfer: ".scalar(@{$threads})."\n";

    #my $k = 0;
    foreach my $thread (@{$threads}) {
        print "Threads to go: ".--$totalThreads."\n";
        #print "Thread ID :".$thread->getId."\n\n";
        my $threadId = $thread->getId;
        #Get the url of the thread so we can reuse it.
        my $url      = $thread->getUrl;
        #Change the url of the thread so we can reuse it
        $thread->update({ url=>"thread-tmp-url" });
        #Purge all the old revisions of the thread so we can reuse the url
        my $rs = $db->read("select revisionDate from assetData where assetId=? and revisionDate<>?",[$threadId, $thread->get("revisionDate")]);
        while (my ($version) = $rs->array) {
            my $old = WebGUI::Asset->new($session, $threadId, $thread->get("className"), $version);
            $old->purgeRevision if defined $old;
        }

        my $status = ($thread->get("status") eq "archived") ? "closed" : "pending";

        my $ref = {
            className         =>"WebGUI::Asset::Ticket",
            title             => $thread->get("title"),
            menuTitle         => $thread->get("title"),
            url               => $url,
            ownerUserId       => $thread->get("ownerUserId"),
            synopsis          => scrubHTML($thread->get("content")),
            isHidden          => 1,
            ticketId          => $session->db->getNextId("ticketId"),
            ticketStatus      => $status,
            karmaScale        => $thread->get("karmaScale"),
            karma             => $thread->get("karma"),
            karmaScale        => $thread->get("karmaScale"),
            karmaRank         => $thread->get("karmaRank"),
        };
        #print Dumper($ref)."\n\n";
        #Post the ticket to the help desk
        my $ticket     = $helpDesk->addChild($ref,undef,$thread->get('revisionDate'),{ skipAutoCommitWorkflows=>1 });
        
        #Skip notifications
        $ticket->setSkipNotification;

         #Create the subscription group and migrate all the users
        my $ticketSubGroup   = $ticket->getSubscriptionGroup;
        my $threadSubGroupId = $thread->get('subscriptionGroupId');
        if ($threadSubGroupId) {
            my $users = WebGUI::Group->new($session,$threadSubGroupId)->getUsers(1);
            $ticketSubGroup->addUsers($users);
        }
        
        #Create the storage location for the ticket and copy all the files
        my $newstore = $ticket->getStorageLocation;
        my $oldstore = $thread->getStorageLocation;
        $oldstore->copy($newstore);

        #Insert the thread assetId mapping reference.
        $db->write("insert into Ticket_collabRef values (?,?)",[$threadId,$ticket->getId]);
    
        #Convert all the posts into comments
        my $posts = $thread->getLineage(["descendants"],{
            returnObjects      => 1,
            includeOnlyClasses => ["WebGUI::Asset::Post"],
            orderByClause      => "asset.creationDate asc",
            statusToInclude    => ["approved","archived"],
            includeArchived    => 1
        });

        my $count     = 0;
        my $sum       = 0;
        my $index     = 0;
        my $postCount = scalar(@{$posts});
        my $comments  = []; 
        foreach my $post (@{$posts}) {
            my $rating = 0;
            if($rating < -10) {
                $rating = 1;
            }
            elsif($rating < 0) {
                $rating = 2;
            }
            elsif($rating >= 50) {
                $rating = 5;
            }
            elsif($rating > 10) {
                $rating = 4;
            }
            elsif($rating > 0) {
                $rating = 3;
            }

            my $content = scrubHTML($post->get("content"));
            WebGUI::Macro::negate(\$content);
           
            push (@{$comments},{
                id      => $post->getId,
                alias   => $post->get("username"),
                userId  => $post->get("ownerUserId"),
                comment => $content,
                rating  => $rating,
                date    => $post->get('creationDate'),
                ip      => "",
            });

            $sum += $rating;
            $count++ if($rating); #Don't count unrated posts
            #Copy all the uplaods to the ticket
            my $poststore = $post->getStorageLocation;
            if($poststore) {
                $poststore->copy($newstore);
            }
            if(++$index == $postCount) {
                $ticket->update({
                    lastReplyDate => $post->get("creationDate"),
                    lastReplyBy   => $post->get("ownerUserId")
                });
            }
            #Insert the thread assetId mapping reference.
            $db->write("insert into Ticket_collabRef values (?,?)",[$post->getId,$ticket->getId]);
            $post->purge unless($test); #Delete the post 
            $post = undef;
        }

        #Avoid divide by zero errors
        $count        = 1 unless ($count);
        my $avgRating = $sum/$count;
        #print Dumper($comments)."\n\n";
        $ticket->update({
            comments       => encode_json($comments),
            averageRating  => $avgRating,
        });

        #Add the user defined data from the thread
        foreach my $id (keys %{$metaFields}) {
            my $hash    = $metaFields->{$id};
            my $fieldId = $hash->{fieldId};
            my $value   = $thread->get($id);

            if($hash->{valuesMap}) {
                $value   = $hash->{valuesMap}->{$value}
            }

            #print Dumper($hash)."\n\n";
            #print "$id = $value \n\n";
            
            $db->write(
                "replace into Ticket_metaData (fieldId,assetId,value) values (?,?,?)",
                [$fieldId,$ticket->getId,$value]
            );
        }

        #Update the original post date of the thread
        $db->write("update asset set creationDate=?, createdBy=? where assetId=?",[
            $thread->get("creationDate"),
            $thread->get("createdBy"),
            $ticket->getId
        ]);
        #Delete the thread and all of it's posts
        $thread->purge unless($test);
        $thread = undef;
        #last if ($k++ == 5);
    }

    #Delete the Collaboration system
    $collab->purge unless ($test);
    
}

###############################################
#       Clean Up
###############################################

# Commit all the assets created by this process
print "Committing version tag..." unless ($quiet);
$versionTag->commit;
print " Done!\n" unless($quiet);

#Clear the cache
print "Clearing Cache..." unless ($quiet);
system("rm -Rf /tmp/WebGUICache/");
print " Done!\n" unless($quiet);

print "Cleaning up..." unless ($quiet);
$session->var->end;
$session->close;
print "OK\n" unless ($quiet);


###############################################
#         End
###############################################


#-------------------------------------------------------------------

=head2 scrubHTML ( html )

Takes the message and tries to return just the content that should be posted removing replyto blocks and unecessary HTML

=head3 html

The html segment you want to convert to text.

=cut

sub scrubHTML {
	my $html     = shift;
	my $newHtml  = "";
	my $skip     = 0;
    my $checkTag = "";
    my @skipTags = ("html","body","meta");

	my $startTagHandler = sub {
		my($tag, $num,$attr,$text) = @_;
        #print "Start Tag: $tag   Id: ".$attr->{id}."\n";
        if($checkTag eq "" && (
            $tag eq "head"
            || $tag eq "blockquote"
            || ($tag eq "hr" && $attr->{id} eq "EC_stopSpelling")  #Hotmail / MSN
            || ($tag eq "div" && $attr->{class} eq "gmail_quote")  #Gmail
            || ($tag eq "table" && $attr->{border} == 0 && $attr->{cellspacing} == 2 && $attr->{cellpadding} == 3) #Previoius posts
            )
        ) {
            $skip = 1;
            $checkTag  = $tag;
            return;
        }
        #Start counting nested tags
        $skip++ if($tag eq $checkTag);
        
        return if ($skip);
        return if (isIn($tag,@skipTags));
        
        $newHtml .= $text;
	};
    
    my $endTagHandler = sub {
        my ($tag, $num, $text) = @_;
        #print "End Tag: $tag \n";
        return if (isIn($tag,@skipTags));
        if($skip == 0) {
            $newHtml .= $text;
            return;
        }
        #Decrement the nested tag counter
        $skip-- if($tag eq $checkTag);
        #Unset checktag if the counter hits zero
        $checkTag = "" if($skip == 0);
    };

	my $textHandler = sub {
        my $text = shift;
		return if($skip);
        if ($text =~ /\S+/) {
            $newHtml .= $text;
		}
	};

	HTML::Parser->new(
        api_version     => 3,
		handlers        => [
            start => [$startTagHandler, "tagname, '+1', attr, text"],
			end   => [$endTagHandler, "tagname, '-1', text"],
			text  => [$textHandler, "text"],
		],
		marked_sections => 1,
	)->parse($html);
    
    $newHtml = WebGUI::HTML::cleanSegment($newHtml);    
	return $newHtml;
}
