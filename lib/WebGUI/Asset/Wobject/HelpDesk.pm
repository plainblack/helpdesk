package WebGUI::Asset::Wobject::HelpDesk;

$VERSION = "1.0.0";

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use Moose;
use Tie::IxHash;
use WebGUI::Definition::Asset;
extends 'WebGUI::Asset::Wobject';
use WebGUI::International;
use JSON;

define assetName => ['assetName', 'Asset_HelpDesk'];
define tableName => 'HelpDesk';

property sortColumn => (
    fieldType    => "selectBox",
    options      => sub { shift->getSortOptions },
    defaultValue => 'creationDate',
    tab          => "display",
    hoverHelp    => 'Choose how you would like the tickets in this help desk to be sorted',
    label        => 'Sort Column',
);
property sortOrder => (
    fieldType    => "selectBox",
    options      => sub { shift->getSortDirs },
    defaultValue => 'DESC',
    tab          => "display",
    hoverHelp    => 'Choose the direction you would like to sort the columns',
    label        => 'Sort Direction',
);
property viewTemplateId => (
    fieldType    => "template",
    defaultValue => 'HELPDESK00000000000001',
    tab          => "display",
    namespace    => "HelpDesk/view",
    hoverHelp =>
        'Choose the template to use for the main view which is the tab wrapper of the other views',
    label => 'Main View Template',
);
property viewMyTemplateId => (
    fieldType    => "template",
    defaultValue => 'HELPDESK00000000000002',
    tab          => "display",
    namespace    => "HelpDesk/myView",
    hoverHelp    => 
        'Choose the template to use for the my view which is the global contents of all tickets assigned to the current user',
    label => 'My View Template',
);
property viewAllTemplateId => (
    fieldType    => "template",
    defaultValue => 'HELPDESK00000000000003',
    tab          => "display",
    namespace    => "HelpDesk/viewAll",
    hoverHelp    => 
        'Choose the template to use for the all view which displays all of the tickets local to this asset',
    label => 'View All Template',
);
property searchTemplateId => (
    fieldType    => "template",
    defaultValue => 'HELPDESK00000000000004',
    tab          => "display",
    namespace    => "HelpDesk/search",
    hoverHelp =>
        'Choose the template to use for the search tab which allows users to search for and find tickets',
    label => 'Search Template',
);
property manageMetaTemplateId => (
    fieldType    => "template",
    defaultValue => 'HELPDESK00000000000005',
    tab          => "display",
    namespace    => "HelpDesk/manageMeta",
    hoverHelp    => 'Choose the template to use for managing help desk meta data',
    label        => 'Manage Meta Data Template',
);
property editMetaFieldTemplateId => (
    fieldType    => "template",
    defaultValue => 'HELPDESK00000000000006',
    tab          => "display",
    namespace    => "HelpDesk/editMetaField",
    hoverHelp    => 'Choose the template to use for editing help desk meta fields',
    label        => 'Edit Meta Field Template',
);
property notificationTemplateId => (
    fieldType    => "template",
    defaultValue => 'HELPDESK00000000000007',
    tab          => "display",
    namespace    => "HelpDesk/notify",
    hoverHelp    => 'Choose the template to use for sending email',
    label        => 'Notification Tempalte',
);
property editTicketTemplateId => (
    fieldType    => "template",
    defaultValue => 'TICKET0000000000000001',
    tab          => "display",
    namespace    => "Ticket/edit",
    hoverHelp    => 'Choose the template to use for editing a ticket',
    label        => 'Edit Ticket Template',
);
property viewTicketTemplateId => (
    fieldType    => "template",
    defaultValue => 'TICKET0000000000000002',
    tab          => "display",
    namespace    => "Ticket/view",
    hoverHelp    => 'Choose the template to use for the main view of a ticket',
    label        => 'View Ticket Template',
);
property viewTicketRelatedFilesTemplateId => (
    fieldType    => "template",
    defaultValue => 'TICKET0000000000000003',
    tab          => "display",
    namespace    => "Ticket/relatedFiles",
    hoverHelp    => 'Choose the template to use for displaying related files when viewing a ticket',
    label        => 'Related Files for View Ticket Template',
);
property viewTicketUserListTemplateId => (
    fieldType    => "template",
    defaultValue => 'TICKET0000000000000004',
    tab          => "display",
    namespace    => "Ticket/userList",
    hoverHelp =>
        'Choose the template to use for displaying the list of users when assigning a ticket to a user',
    label => 'User List for View Ticket Template',
);
property viewTicketCommentsTemplateId => (
    fieldType    => "template",
    defaultValue => 'TICKET0000000000000005',
    tab          => "display",
    namespace    => "Ticket/comments",
    hoverHelp    => 'Choose the template to use for displaying the comments when viewing a ticket',
    label        => 'Comments for View Ticket Template',
);
property viewTicketHistoryTemplateId => (
    fieldType    => "template",
    defaultValue => 'TICKET0000000000000006',
    tab          => "display",
    namespace    => "Ticket/history",
    hoverHelp    => 'Choose the template to use for displaying the history when viewing a ticket',
    label        => 'History for View Ticket Template',
);
property groupToPost => (
    tab          => "security",
    fieldType    => "group",
    defaultValue => 2,                                                                         # Registered Users
    label        => "Who can post?",
    hoverHelp    => "Choose the group of users that can post bugs to the list",
);
property groupToChangeStatus => (
    tab          => "security",
    fieldType    => "group",
    defaultValue => 3,                                                                         # Admins
    label        => "Who can change status?",
    hoverHelp    => 
        "Choose the group of users that can change the status of a bug.  By default the user assigned to the ticket and users who can edit the help desk will already have this privilege.  This is an additional group that can work on tickets",
);
property richEditIdPost => (
    tab          => "display",
    fieldType    => "selectRichEditor",
    defaultValue => "PBrichedit000000000002",                                                  # Forum Rich Editor
    label        => "Post Rich Editor",
    hoverHelp    => "Choose the rich editor to use for posting",
);
property karmaEnabled => (
    tab          => "properties",
    fieldType    => "yesNo",
    defaultValue => 0,
    visible      => sub { shift->session->setting->get('useKarma') },
    label        => "Enable Karma",
    hoverHelp    => 
        "This enabled or disables karma and is used to determine whether or not to enable the karma settings on this HelpDesk",
);
property defaultKarmaScale => (
    tab          => "properties",
    fieldType    => "integer",
    defaultValue => 1,
    visible      => sub { shift->session->setting->get('useKarma') },
    label        => "Default Karma Scale",
    hoverHelp    => 
        "This is the default value that will be assigned to the karma scale field in threads. Karma scale is a weighting mechanism for karma sorting that can be used for handicaps, difficulty, etc.",
);
around defaultKarmaScale => sub {
    my $orig = shift;
    my $self = shift;
    return $self->$orig if !@_;
    my $value = shift || 1;
    return $self->$orig($value);
};
property karmaPerPost => (
    tab          => "properties",
    fieldType    => "integer",
    defaultValue => 0,
    visible      => sub { shift->session->setting->get('useKarma') },
    label        => "Karma Per Post",
    hoverHelp    => "Enter the amount of karma that should be given each time a user posts a comment",
);
property karmaToClose => (
    tab          => "properties",
    fieldType    => "integer",
    defaultValue => 0,
    visible      => sub { shift->session->setting->get('useKarma') },
    label        => "Karma To Close",
    hoverHelp    => 
        "Enter the amount of karma that should be given to the person assigned to the ticket once it is closed",
);
property subscriptionGroup => (
    fieldType    => "subscriptionGroup",
    tab          => 'security',
    label        => "Subscription Group",
    hoverHelp    => "The group that users subscribed to this help desk are members of",
    noFormPost   => 1,
    defaultValue => undef,
);
property approvalWorkflow => (
    fieldType    => "workflow",
    defaultValue => "pbworkflow000000000003",
    type         => 'WebGUI::VersionTag',
    tab          => 'security',
    label        => ['approval workflow','Asset_HelpDesk'],
    hoverHelp    => ['approval workflow description','Asset_HelpDesk'],
);
property autoSubscribeToTicket => (
    fieldType    => "yesNo",
    defaultValue => 1,
    tab          => 'mail',
    label        => ["auto subscribe to ticket",'Asset_HelpDesk'],
    hoverHelp    => ["auto subscribe to ticket help",'Asset_HelpDesk'],
);
property requireSubscriptionForEmailPosting => (
    fieldType    => "yesNo",
    defaultValue => 1,
    tab          => 'mail',
    label        => ["require subscription for email posting",'Asset_HelpDesk'],
    hoverHelp    => ["require subscription for email posting help",'Asset_HelpDesk'],
);
property mailServer => (
    fieldType    => "text",
    defaultValue => undef,
    tab          => 'mail',
    label        => ["mail server",'Asset_HelpDesk'],
    hoverHelp    => ["mail server help",'Asset_HelpDesk'],
);
property mailAccount => (
    fieldType    => "text",
    defaultValue => undef,
    tab          => 'mail',
    label        => ["mail account",'Asset_HelpDesk'],
    hoverHelp    => ["mail account help",'Asset_HelpDesk'],
);
property mailPassword => (
    fieldType    => "password",
    defaultValue => undef,
    tab          => 'mail',
    label        => ["mail password",'Asset_HelpDesk'],
    hoverHelp    => ["mail password help",'Asset_HelpDesk'],
);
property mailAddress => (
    fieldType    => "email",
    defaultValue => undef,
    tab          => 'mail',
    label        => ["mail address",'Asset_HelpDesk'],
    hoverHelp    => ["mail address help",'Asset_HelpDesk'],
);
property mailPrefix => (
    fieldType    => "text",
    defaultValue => undef,
    tab          => 'mail',
    label        => ["mail prefix",'Asset_HelpDesk'],
    hoverHelp    => ["mail prefix help",'Asset_HelpDesk'],
);
property getMailCronId => (
    fieldType    => "hidden",
    defaultValue => undef,
    noFormPost   => 1
);
property getMail => (
    fieldType    => "yesNo",
    defaultValue => 0,
    tab          => 'mail',
    label        => ["get mail",'Asset_HelpDesk'],
    hoverHelp    => ["get mail help",'Asset_HelpDesk'],
);
property getMailInterval => (
    fieldType    => "interval",
    defaultValue => 300,
    tab          => 'mail',
    label        => ["get mail interval",'Asset_HelpDesk'],
    hoverHelp    => ["get mail interval help",'Asset_HelpDesk'],
);
property closeTicketsAfter => (
    fieldType    => "interval",
    defaultValue => 1209600,
    tab          => 'properties',
    label        => "Close Tickets After",
    hoverHelp    => "Resolved tickets get closed after this period of time",
);
property runOnNewTicket => (
    fieldType  => 'workflow',
    tab        => 'display',
    noFormPost => 0,
    hoverHelp  => 'Workflow to kick off after adding new ticket',
    label      => 'Run on New Ticket',
);
property localTicketsOnly => (
    fieldType    => 'yesNo',
    tab          => 'display',
    defaultValue => '0',
    hoverHelp    => 'By default, the helpdesk displays tickets from all tickets in the system in the My Tickets tab.  Selecting Yes, will limit display of tickets to only those in this Helpdesk.',
    label        => 'Show local tickets only?',
);

#-------------------------------------------------------------------
sub _getUsersHash {
    my $self     = shift;
    my $db       = $self->session->db;    
    my $column   = shift;
    my $defaults = shift || {};

    unless(scalar(keys %{$defaults})) {
        $defaults = {""=>"Any"};
    }

    tie my %hash, "Tie::IxHash";
    
    my $sql = qq{
        select
            distinct $column,
            username
        from
            Ticket
            join asset using(assetId)
            join users on users.userId=$column
        where
            $column is not NULL
            and lineage like ?
        order by username
    };

    %hash = $db->buildHash($sql,[$self->lineage."%"]);
    %hash = (%{$defaults},%hash);

    return \%hash;
}

#-------------------------------------------------------------------

=head2 canEdit

Determine if the user has permission to post a ticket to the help desk

=head3 userId

User to check edit privileges of

=head3 ignoreNew

If this flag is set, canEdit will ignore the new conditions even if the ticket being submitted is new.

=cut

around canEdit => sub {
    my $orig      = shift;
    my $self      = shift;
    my $session   = $self->session;
    my $form      = $session->form;
    my $func      = $form->get("func");
    my $assetId   = $form->get("assetId");
    my $userId    = shift || $session->user->userId;
    my $ignoreNew = shift;

    #Adding tickets from the help desk    
    if(!$ignoreNew
        && $userId eq $session->user->userId
        && $form->get("class") eq "WebGUI::Asset::Ticket"
        && ($func eq "add" || ($func eq "editSave" && $assetId eq "new" ))
    ) {
        my $user = WebGUI::User->new($session,$userId);
        return $user->isInGroup($self->groupToPost);
    }
    
    return $self->$orig($userId);
};

#-------------------------------------------------------------------

=head2 canPost

Determine if the user has permission to post a ticket to the help desk

=cut

sub canPost {
    my $self    = shift;
    my $userId  = shift;

    my $user    = undef;
    if($userId) {
        $user = WebGUI::User->new($self->session,$userId)
    }
    else {
        $user   = $self->session->user;
        $userId = $user->userId;
    }

    return ($user->isInGroup($self->groupToPost) || $self->canEdit($userId));
}

#-------------------------------------------------------------------
sub canSubscribe {
    my $self    = shift;
    my $userId  = shift || $self->session->user->userId;
    return ($userId ne "1" && $self->canView($userId) );
}

#-------------------------------------------------------------------
override commit => sub {
    my $self = shift;
    my $i18n = $self->i18n;
    my $cron = undef;
    
    super();
    
    #Handle setting up the cron job
    if ($self->getMailCronId) {
        $cron = WebGUI::Workflow::Cron->new($self->session, $self->getMailCronId);
    }
    unless (defined $cron) {
        $cron = WebGUI::Workflow::Cron->create($self->session, {
            title        =>$self->getTitle." ".$i18n->echo("Mail"),
            minuteOfHour =>"*/".($self->getMailInterval/60),
            className    =>(ref $self),
            methodName   =>"new",
            parameters=>$self->getId,
            workflowId=>"hdworkflow000000000001"
        });
        $self->update({ getMailCronId => $cron->getId });
    }
    
    if ($self->getMail) {
        $cron->set({
            enabled=>1,
            title=>$self->getTitle." ".$i18n->get("mail"),
            minuteOfHour=>"*/".($self->getMailInterval/60)
        });
    }
    else {
        $cron->set({
            enabled=>0,
            title=>$self->getTitle." ".$i18n->get("mail"),
            minuteOfHour=>"*/".($self->getMailInterval/60)
        });
    }
};

#-------------------------------------------------------------------
sub createSubscriptionGroup {
	my $self  = shift;
    my $asset = shift || $self;
    my $type  = shift || "help desk";
    my $id    = shift || $self->getId;

	my $group = WebGUI::Group->new($self->session, "new");

	$group->name($id);
	$group->description("The group to store subscriptions for $type $id");
	$group->isEditable(0);
	$group->showInForms(0);
	$group->deleteGroups([3]); # admins don't want to be auto subscribed to this thing
	$asset->update({
        subscriptionGroup=>$group->getId
	});
    return $group;
}

#-------------------------------------------------------------------
sub getContentLastModified {
    return time;
}

#-------------------------------------------------------------------

=head2 getEditTabs

Add a tab for the mail interface.

=cut

override addEditSaveTabs => sub {
	my $self = shift;
    my $form = super();
    $form->addTab(name => 'mail', label => 'Mail', ); ##uiLevel used to be 9
    return $form;
};

#------------------------------------------------------------------

=head2 getHelpDeskMetaField (  )

Returns a hashref of a single help desk meta field

=cut

sub getHelpDeskMetaField {
	my $self       = shift;
    my $fieldId    = shift;

    return {} unless $fieldId;

    my $sql = "select * from HelpDesk_metaField where fieldId=?";

    return $self->session->db->quickHashRef($sql,[$fieldId]);
}

#------------------------------------------------------------------

=head2 getHelpDeskMetaFieldByLabel (  )

Returns a hashref of a single help desk meta field looked up by label

=cut

sub getHelpDeskMetaFieldByLabel {
    my $self    = shift;
    my $label   = shift;
    my $assetId = $self->getId;

    return {} unless ( $label && $assetId );

    my $sql = qq{
        SELECT *
        FROM HelpDesk_metaField
        WHERE label = ?
        AND assetId = ?
    };

    return $self->session->db->quickHashRef( $sql, [ $label, $self->getId ] );
}

#------------------------------------------------------------------

=head2 getHelpDeskMetaFields (  )

Returns an arrayref of hash references of the metadata fields.

=cut

sub getHelpDeskMetaFields {
	my $self       = shift;
    my $props      = shift || {};
    my $asHash     = $props->{returnHashRef};
    my $searchOnly = $props->{searchOnly};

    #my $db   = $self->session->db;
    my $dbh  = $self->session->db->dbh;
    
    my $clause = "";
    if($searchOnly) {
        $clause .= " and searchable=1"
    }

    my $sql = "select * from HelpDesk_metaField where assetId=? $clause order by sequenceNumber";

    if($asHash) {
        my $hashRef = $dbh->selectall_hashref(
            $sql,
            "fieldId",
            {},
            $self->getId
        );
        $hashRef = {} unless (defined $hashRef);
        return $hashRef;
    }

    my $arrRef = $dbh->selectall_arrayref(
      $sql,
      { Slice => {} },
      $self->getId
    );
    $arrRef = [] unless (defined $arrRef);
    return $arrRef;
}

#-------------------------------------------------------------------
sub getStatus {
    my $self  = shift;
    my $key   = shift;

    unless ($self->{_status}) {
        tie my %hash, "Tie::IxHash";
        my $i18n = $self->i18n;
        for my $item ( 
            'pending',
            'acknowledged',
            'waiting',
            'feedback',
            'confirmed',
            'resolved',
            'closed',
			) {
            $hash{$item} = $i18n->get($item),
        }
        $self->{_status} = \%hash;
    }

    if($key) {
        return $self->{_status}->{$key};
    }
    
    return $self->{_status};
}

#-------------------------------------------------------------------
sub getSortDirs {
    my $self  = shift;
    
    tie my %options, "Tie::IxHash";
    %options = (
        ASC      =>"Ascending",
        DESC     =>"Descending",
    );

    return \%options;
}


#-------------------------------------------------------------------
sub getSortOptions {
    my $self  = shift;
    
    tie my %options, "Tie::IxHash";
    %options = (
        ticketId      =>"Ticket Id",
        title         =>"Subject",
        createdBy     =>"Submitted By",
        creationDate  =>"Submitted On",
        assignedTo    =>"Assigned To",
        ticketStatus  =>"Status",
        lastReplyDate =>"Last Reply",
        karmaRank     =>"Karma Rank"
    );

    return \%options;
}

#-------------------------------------------------------------------
sub getSubscriptionGroup {
	my $self  = shift;

    my $group = $self->subscriptionGroup;
    if ($group) {
		$group = WebGUI::Group->new($self->session,$group);
	}
    #Group Id was stored in the database but someone deleted the actual group
    unless($group) {
        $group = $self->createSubscriptionGroup;
    }
    return $group;
}

#-------------------------------------------------------------------
sub i18n {
	my $self    = shift;
    my $session = $self->session;
    
    unless ($self->{_i18n}) { 
        $self->{_i18n} = WebGUI::International->new($session, "Asset_HelpDesk");
    }
    return $self->{_i18n};
}

#-------------------------------------------------------------------
sub indexTickets {
    my $self  = shift;
    
    my $tickets = $self->getLineage(['children'],{ includeOnlyClasses=> ['WebGUI::Asset::Ticket'], returnObjects=>1 });
    
    foreach my $ticket (@{$tickets}) {
        $ticket->update({});
    }
}

#-------------------------------------------------------------------

=head2 isSubscribed ( [userId]  )

Returns a boolean indicating whether the user is subscribed to the help desk.

=cut

sub isSubscribed {
    my $self    = shift;
    my $userId  = shift;
    
    my $user    = undef;
    if($userId) {
        $user = WebGUI::User->new($self->session,$userId)
    }
    else {
        $user   = $self->session->user;
    }

    return 0 unless ($self->subscriptionGroup);
	return $user->isInGroup($self->subscriptionGroup);
}

#-------------------------------------------------------------------
sub karmaIsEnabled {
    my $self = shift;
    return ($self->session->setting->get("useKarma") && $self->karmaEnabled);
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

override prepareView => sub {
	my $self = shift;
	super;
	my $template = WebGUI::Asset::Template->new($self->session, $self->viewTemplateId);

	$template->prepare;
	$self->{_viewTemplate} = $template;
};

#----------------------------------------------------------------------------

=head2 processEditForm ( )

Extend the base method to guarantee a subscription group exists.

=cut

override processEditForm => sub {
    my $self    = shift;
    super();

    $self->getSubscriptionGroup(); 

    return undef;
};

#-------------------------------------------------------------------
override purge => sub {
	my $self    = shift;
    my $session = $self->session;

    #Delete the subscription group
	my $group = WebGUI::Group->new($session, $self->subscriptionGroup);
	$group->delete if ($group);
    
    #Delete the mail cron
    if ($self->getMailCronId) {
		my $cron = WebGUI::Workflow::Cron->new($session, $self->getMailCronId);
		$cron->delete if defined $cron;
	}

    #Delete all the metadata fields
    $session->db->write("delete from HelpDesk_metaField where assetId=?",[$self->getId]);

    super();
};

#-------------------------------------------------------------------

=head2 view ( )

method called by the www_view method.  Returns a processed template
to be displayed within the page style.  

=cut

sub view {
	my $self    = shift;
	my $session = $self->session;
    my $i18n    = $self->i18n;

	#This automatically creates template variables for all of your wobject's properties.
	my $var = $self->get;
	
    $var->{'canPost'       } = $self->canPost;
    $var->{'canEdit'       } = $self->canEdit;
    $var->{'canEditAndPost'} = $var->{'canPost'} && $var->{'canEdit'};
    $var->{'canSubscribe'  } = $self->canSubscribe;

    #$var->{'url_viewAll'    } = $self->getUrl("func=viewAllTickets");
    #$var->{'url_viewMy'     } = $self->getUrl("func=viewMyTickets");
    #$var->{'url_search'     } = $self->getUrl("func=search");
    $var->{'url_subscribe'  } = $self->getUrl("func=toggleSubscription");
    $var->{'subscribe_label'} = ($self->isSubscribed) ? $i18n->get("unsubscribe_link") : $i18n->get("subscribe_link");

    if($var->{'canPost'}) {
	    $var->{'url_addTicket'} = $self->getUrl("func=add;className=WebGUI::Asset::Ticket");
    }
    if($var->{'canEdit'}) {
       $var->{'url_manageMetaData'} = $self->getUrl("func=manageHelpDeskMetaFields");
    }
    $var->{viewAllTab} = $self->www_viewAllTickets();
    $var->{viewMyTab} = $self->www_viewMyTickets();
    $var->{searchTab} = $self->www_search();
	
	return $self->processTemplate($var, undef, $self->{_viewTemplate});
}

#-------------------------------------------------------------------

=head2 www_copy ( )

Overrides the default copy functionality and does nothing.

=cut

sub www_copy {
    my $self = shift;
    return $self->session->privilege->insufficient unless $self->canEdit;
    return $self->processStyle("Help Desk applications cannot be copied");
}


#-------------------------------------------------------------------

=head2 www_deleteHelpDeskMetaField ( )

Processes the results from www_deleteHelpDeskMetaField ().

=cut

sub www_deleteHelpDeskMetaField {
	my $self    = shift;
    my $session = $self->session;
	my $form    = $session->form;
    my $i18n    = $self->i18n;
    my $db      = $session->db;

    return $session->privilege->insufficient unless ($self->canEdit);
	
    my $error   = "";
    my $fieldId = $form->get("fieldId");
    
    my $columnName  = "field_".$fieldId;
    
    my $data = $db->quickHashRef('select * from HelpDesk_metaField where fieldId=?',[$fieldId]);
    #Delete the column from the Ticket_searchIndex table
    if ($data->{searchable}) {
        $db->write("ALTER TABLE Ticket_searchIndex DROP COLUMN " . $db->dbh->quote_identifier($columnName));
    }
    $db->write("DELETE FROM Ticket_metaData WHERE fieldId=?",[$fieldId]);
    $db->write("DELETE FROM HelpDesk_metaField WHERE fieldId=?",[$fieldId]);

	return $self->www_manageHelpDeskMetaFields();
}

#-------------------------------------------------------------------

=head2 www_editHelpDeskMetaField ( )

Displays the edit form for help desk meta fields.

=cut

sub www_editHelpDeskMetaField {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;
    my $db      = $session->db;
    my $i18n    = $self->i18n;

	my $fieldId         = shift || $form->process("fieldId") || "new";
	my $var             = {};
    $var->{'error_msg'} = shift;
    
    return $session->privilege->insufficient unless ($self->canEdit);

	my $data = $db->quickHashRef("select * from HelpDesk_metaField where fieldId=?",[$fieldId]);
    
    $var->{'form_start'         } = WebGUI::Form::formHeader($session, {
        action       => $self->getUrl('func=editHelpDeskMetaFieldSave;fieldId='.$fieldId),
    });
    
    $var->{'form_label'         } = WebGUI::Form::text($session, {
		name         => "label",
		value        => $form->get("label") || $data->{label},
        defaultValue => "",
	});
    
    $var->{'form_dataType'      } = WebGUI::Form::fieldType($session, {
        name         => "dataType",        
        value        => ucfirst($form->get("dataType") || $data->{dataType}),        
        defaultValue => "Text",
    });

    $var->{'form_required'      } = WebGUI::Form::yesNo($session, {
		name         => "required",
		value        => $form->get("yesNo") || $data->{required},
        defaultValue => 0
	});
    
    $var->{'form_searchable'    } = WebGUI::Form::yesNo($session, {
		name         => "searchable",
		value        => $form->get("searchable") || $data->{searchable},
		defaultValue => 1,
	});

         # meta field sorting is not yet available,  needs some design work
    $var->{'form_sortable'    } = WebGUI::Form::yesNo($session, {
		name         => "sortable",
		value        => 0, # $form->get("sortable") || $data->{sortable},
		defaultValue => 0,
	});

    $var->{'form_showInList'    } = WebGUI::Form::yesNo( $session, {
        name            => "showInList",
        value           => $form->get("showInList") || $data->{showInList},
        defaultValue    => 0,
    });
    
    $var->{'hh_possibleValues'  } = $i18n->get('hoverHelp_possibleValues');
    $var->{'form_possibleValues'} = WebGUI::Form::textarea($session, {
		name         => "possibleValues",
		value        => $form->get("possibleValues") || $data->{possibleValues},
	});
 
    $var->{'hh_defaultValues'  } = $i18n->get('hoverHelp_defaultValues');
    $var->{'form_defaultValues'} = WebGUI::Form::textarea($session, {
		name         => "defaultValues",
		value        => $form->get("defaultValues") || $data->{defaultValues},
	});

    $var->{'form_hoverHelp'} = WebGUI::Form::HTMLArea( $session, {
        name        => "hoverHelp",
        value       => ( $form->get("hoverHelp") || $data->{hoverHelp} ),
        richEditId  => $self->richEditIdPost,
        height      => 300,
    });

    $var->{'form_submit'       } = WebGUI::Form::submit($session, {
        name        => "submit",
        value       => $i18n->echo("Save"),
    });
    
    $var->{'form_end'          } = WebGUI::Form::formFooter( $session );

    return $self->processStyle(
        $self->processTemplate( $var, $self->editMetaFieldTemplateId )
    );
}

#-------------------------------------------------------------------

=head2 www_editHelpDeskMetaFieldSave ( )

Processes the results from www_editHelpDeskMetaField ().

=cut

sub www_editHelpDeskMetaFieldSave {
	my $self    = shift;
    my $session = $self->session;
	my $form    = $session->form;
    my $i18n    = $self->i18n;
    my $db      = $session->db;

    return $session->privilege->insufficient unless ($self->canEdit);
	
    my $error   = "";
    my $fieldId = $form->get("fieldId");

    my @requiredFields = ("label");
    foreach my $field (@requiredFields) {
		if ($form->get($field) eq "") {
			$error .= sprintf("The %s field cannot be blank.",$field)."<br />";
		}
	}
	return $self->www_editHelpDeskMetaField($fieldId,$error) if $error;

    my ($origFieldType,$wasSearchable) = $session->db->quickArray(
        "select dataType, searchable from HelpDesk_metaField where fieldId=?",
        [$fieldId]
    );

    my $fieldType       = $form->process("dataType",'fieldType');
    my $searchable      = $form->process("searchable",'yesNo');
    my $sortable        = 0; # $form->process("sortable",'yesNo');
    my $newId = $self->setCollateral("HelpDesk_metaField", "fieldId",{
        fieldId        => $fieldId,
		label          => $form->process("label"),
		dataType       => $fieldType,
		searchable     => $searchable,
		#sortable       => $sortable,
        showInList      => $form->process("showInList","yesNo"),
		required       => $form->process("required",'yesNo'),
		possibleValues => $form->process("possibleValues",'textarea'),
		defaultValues  => $form->process("defaultValues",'textarea'),
        hoverHelp      => $form->process("hoverHelp",'HTMLArea'),
	},1,1);
    
    # Get the field's data type
    my $formClass   = 'WebGUI::Form::' . ucfirst $fieldType;
    eval "use $formClass;";
    my $dbDataType  = $formClass->getDatabaseFieldType;
    my $columnName  = "field_".$newId;

    if($searchable) {
        if($wasSearchable) {    
            # Modify the column to the Ticket_searchIndex table
            $db->write(
                "ALTER TABLE Ticket_searchIndex MODIFY COLUMN " . $db->dbh->quote_identifier($columnName). " " . $dbDataType
            );
        }
        else {
            # Add the column
            $db->write(
                "ALTER TABLE Ticket_searchIndex ADD COLUMN " . $db->dbh->quote_identifier($columnName). " ".$dbDataType
            );
        }
    }
    elsif($wasSearchable) {
        $db->write(
            "ALTER TABLE Ticket_searchIndex DROP COLUMN " . $db->dbh->quote_identifier($columnName)
        );
    }
    #Re-index the tickets
    $self->indexTickets;

	return $self->www_manageHelpDeskMetaFields();
}

#----------------------------------------------------------------------------

=head2 www_getAllTickets ( session )

Get a page of Asset Manager data, ajax style. Returns a JSON array to be
formatted in a WebGUI HelpDesk data table.

=cut

sub www_getAllTickets {
    my $self        = shift;
    my $session     = $self->session;
    my $datetime    = $session->datetime;
    my $form        = $session->form;
    my $rowsPerPage = 25;
    my $ticketInfo  = {};    
    my $filter      = shift || $form->get("filter");

    return $session->privilege->insufficient unless $self->canView;


    my $orderByColumn    = $form->get( 'orderByColumn' ) || $self->sortColumn;
    my $dir              = $form->get('orderByDirection') || $self->sortOrder;
    my $orderByDirection = lc ($dir) eq "asc" ? "ASC" : "DESC";

    #Only allow specific filter types
    unless($filter ~~ ["myTickets"]) {
        $filter = "";
    }

    my $whereClause = q{Ticket.ticketStatus <> 'closed'};
    if($filter eq "myTickets") {
        my $userId = $session->user->userId;
        $whereClause .= qq{ and ((Ticket.assignedTo='$userId' and Ticket.ticketStatus not in ('resolved','feedback')) or asset.createdBy='$userId') };
    }
    elsif(!$self->canEdit) {    
        my $userId     = $session->user->userId;
        $whereClause .= qq{ and Ticket.ticketStatus <> 'resolved' and (isPrivate=0 || (isPrivate=1 && (assignedTo='$userId' || createdBy='$userId')))};
    }
    else {
        $whereClause .= qq{ and Ticket.ticketStatus <> 'resolved'};
    }

    my $rules;
    $rules->{'joinClass'         } = "WebGUI::Asset::Ticket";
    $rules->{'whereClause'       } = $whereClause;
    $rules->{'includeOnlyClasses'} = ['WebGUI::Asset::Ticket'];
    $rules->{'orderByClause'     } = $session->db->dbh->quote_identifier( $orderByColumn ) . ' ' . $orderByDirection;

    my $sql  = "";
    
    if($filter eq "myTickets" && !$self->get('localTicketsOnly')) {
        $sql = $self->getRoot($session)->getLineageSql(['descendants'], $rules);
    }
    else {
        $sql = $self->getLineageSql(['children'], $rules);
    }

    my $startIndex        = $form->get( 'startIndex' ) || 1;
    $rowsPerPage         = $form->get( 'rowsPerPage' ) || 25;
    my $currentPage         = int ( $startIndex / $rowsPerPage ) + 1;
    
    my $p = WebGUI::Paginator->new( $session, '', $rowsPerPage, 'pn', $currentPage );
    $p->setDataByQuery($sql);

    $ticketInfo->{'recordsReturned'} = $rowsPerPage;
    $ticketInfo->{'totalRecords'   } = $p->getRowCount; 
    $ticketInfo->{'startIndex'     } = $startIndex;
    $ticketInfo->{'sort'           } = $orderByColumn;
    $ticketInfo->{'dir'            } = $orderByDirection;
    $ticketInfo->{'tickets'        } = [];
    
    # Determine which metadata fields we need to send
    my $metafields   = $self->getHelpDeskMetaFields({returnHashRef => 1});
    for my $fieldId ( keys %{$metafields} ) {
        if ( !$metafields->{$fieldId}->{showInList} ) {
            delete $metafields->{$fieldId};
        }
    }

    for my $record ( @{ $p->getPageData } ) {
        my $ticket = WebGUI::Asset->newById( $session, $record->{assetId} );
        
        my $assignedTo = $ticket->assignedTo;
        if ($assignedTo) {
           $assignedTo = WebGUI::User->new($session,$assignedTo)->username;
        }
        else {
           $assignedTo = "unassigned";
        }

        my $lastReplyById = $ticket->lastReplyBy;
        my $lastReplyBy   = $lastReplyById
                          ? WebGUI::User->new($session,$lastReplyById)->username
                          : '';

        # Populate the required fields to fill in
        my $lastReplyDate = $ticket->lastReplyDate;
        if($lastReplyDate) {
            $lastReplyDate = $datetime->epochToHuman($lastReplyDate,"%y-%m-%d @ %H:%n %p");
        }

        my %fields      = (
            ticketId      => $ticket->ticketId,
            url           => $ticket->getUrl,
            title         => $ticket->title,
            createdBy     => WebGUI::User->new($session,$ticket->createdBy)->username,
            creationDate  => $datetime->epochToSet($ticket->creationDate),
            assignedTo    => $assignedTo,
            ticketStatus  => $self->getStatus($ticket->ticketStatus),
            lastReplyDate => $lastReplyDate,
            lastReplyBy   => $lastReplyBy,
            lastReplyById => $lastReplyById,
            karmaRank     => sprintf("%.2f",$ticket->karmaRank),
        );

        # Add metadata fields we should show in the list
	my $metadata = $ticket->getTicketMetaData( );
        for my $fieldId (keys %{$metafields}) {   
            my $field   = $metafields->{ $fieldId };
	    $fields{ "metadata_" . $fieldId } = $metadata->{ $fieldId };
            # look for list fields that require mapped output
	    #   ideally this mapping would be done elsewhere, but I am putting it here
	    #   to avoid breaking anything...
	    for my $checkType ( qw/CheckList ComboBox HiddenList Date DateTime
			           RadioList SelectBox SelectList/ ) {
	        if( $metafields->{$fieldId}{dataType} eq $checkType ) {
		    # make the object and get the value
		    my $props = {
			name         => "field_".$fieldId,
				    value        => $metadata->{$fieldId},
				    defaultValue => undef,
				    options      => $metafields->{$fieldId}->{possibleValues},
			fieldType    => $metafields->{$fieldId}->{dataType},
		    };
		    $fields{ "metadata_" . $fieldId } =
		             WebGUI::Form::DynamicField->new($session,%{$props})->getValueAsHtml;
		    last;
		}
	    }
        }

        push @{ $ticketInfo->{ tickets } }, \%fields;
    }
    
    $session->response->content_type( 'application/json' );
    return JSON->new->encode( $ticketInfo );
}

#-------------------------------------------------------------------

=head2 www_manageHelpDeskMetaFields ( )

Method to display the event metadata management console.

=cut

sub www_manageHelpDeskMetaFields {
	my $self    = shift;
    my $session = $self->session;
    my $icon    = $session->icon;
    my $i18n    = $self->i18n;
    my $var     = {};

	return $session->privilege->insufficient unless ($self->canEdit);

	$var->{'url_editMetaField'} = $self->getUrl("func=editHelpDeskMetaField");
    $var->{'url_viewTickets'  } = $self->getUrl;

    my $count           = 0;
	my $metadataFields  = $self->getHelpDeskMetaFields;
	my $numberOfFields  = scalar(@{$metadataFields});
    
    my $deleteMsg  = $i18n->echo('Are you certain you want to delete this metadata field?  The metadata values for this field will be deleted from all events.');
    my $pageUrl    = $self->url;

    my @fieldsLoop = ();
    foreach my $row (@{$metadataFields}) {
        $count++;
        my $hash    = {};
        my $fieldId = $row->{fieldId}; 
        
		$hash->{'icon_delete'   } = $icon->delete('func=deleteHelpDeskMetaField;fieldId='.$fieldId,$pageUrl,$deleteMsg);
		$hash->{'icon_edit'     } = $icon->edit('func=editHelpDeskMetaField;fieldId='.$fieldId, $pageUrl);
        $hash->{'icon_moveUp'   } = $icon->moveUp('func=moveHelpDeskMetaFieldUp;fieldId='.$fieldId, $pageUrl,($count == 1)?1:0);
		$hash->{'icon_moveDown' } = $icon->moveDown('func=moveHelpDeskMetaFieldDown;fieldId='.$fieldId, $pageUrl,($count == $numberOfFields)?1:0);
			
		$hash->{'metaFieldLabel'} = $row->{label};
	    push(@fieldsLoop,$hash);
    }
    
    $var->{'hasMetaFields'} = $numberOfFields;
    $var->{'fields_loop'  } = \@fieldsLoop;

	return $self->processStyle($self->processTemplate($var, $self->manageMetaTemplateId));
}

#-------------------------------------------------------------------

=head2 www_moveHelpDeskMetaFieldDown ( )

Method to move an help desk meta field down one position in display order

=cut

sub www_moveHelpDeskMetaFieldDown {
	my $self    = shift;
    my $session = $self->session;

	return $session->privilege->insufficient unless ($self->canEdit);
	
    $self->moveCollateralDown('HelpDesk_metaField', 'fieldId', $session->form->get("fieldId"));
	return $self->www_manageHelpDeskMetaFields;
}

#-------------------------------------------------------------------

=head2 www_moveHelpDeskMetaFieldUp ( )

Method to move a help desk metdata field up one position in display order

=cut

sub www_moveHelpDeskMetaFieldUp {
	my $self    = shift;
    my $session = $self->session;
	
    return $session->privilege->insufficient unless ($self->canEdit);
	
    $self->moveCollateralUp('HelpDesk_metaField', 'fieldId', $session->form->get("fieldId"));
	return $self->www_manageHelpDeskMetaFields;
}


#-------------------------------------------------------------------
sub www_viewAllTickets {
    my $self    = shift;
    my $session = $self->session;
    
    return $session->privilege->insufficient unless $self->canView;

    my $var     = {};
    $var->{'url_pageData' } = $self->getUrl('func=getAllTickets;');
    $var->{'karmaEnabled' } = $self->karmaIsEnabled;

    #Set the sort column to creationDate if karma is not enabled.
    my $sortColumn          = $self->sortColumn;

    if($sortColumn eq "karmaRank" && !$var->{'karmaEnabled'}) {
        $sortColumn = "creationDate";
    }

    # Add meta fields
    my $metafields   = $self->getHelpDeskMetaFields({returnHashRef => 1});
    for my $fieldId ( keys %{$metafields} ) {
        if ( $metafields->{$fieldId}->{showInList} ) {
            push @{$var->{meta_fields}}, {
                key     => "metadata_" . $fieldId,
                label   => $metafields->{$fieldId}->{label},
                sortable=> 0, # $metafields->{$fieldId}->{sortable},
            };
        }
    }


    $var->{'sortColumn'   } = $sortColumn;
    $var->{'sortOrder'    } = $self->sortOrder;

    $session->response->content_type( 'text/html' );
    return $self->processTemplate($var, $self->viewAllTemplateId);
}


#-------------------------------------------------------------------
sub www_viewMyTickets {
    my $self    = shift;
    my $session = $self->session;
    my $var     = {};

    return $session->privilege->insufficient unless $self->canView;

    $var->{'url_pageData' } = $self->getUrl('func=getAllTickets;filter=myTickets;');
    $var->{'showKarmaRank'} = $session->setting->get('useKarma');

    #Set the sort column to creationDate if karma is not enabled.
    my $sortColumn          = $self->sortColumn;

    if($sortColumn eq "karmaRank" && !$var->{'karmaEnabled'}) {
        $sortColumn = "creationDate";
    }

    # Add meta fields
    my $metafields   = $self->getHelpDeskMetaFields({returnHashRef => 1});
    for my $fieldId ( keys %{$metafields} ) {
        if ( $metafields->{$fieldId}->{showInList} ) {
            push @{$var->{meta_fields}}, {
                key     => "metadata_" . $fieldId,
                label   => $metafields->{$fieldId}->{label},
                sortable=> 0, # $metafields->{$fieldId}->{sortable},
            };
        }
    }

    $var->{'sortColumn'   } = $sortColumn;
    $var->{'sortOrder'    } = $self->sortOrder;

    return $self->processTemplate($var, $self->viewMyTemplateId);
}

#-------------------------------------------------------------------
sub www_search {
    my $self    = shift;
    my $session = $self->session;
    my $var     = {};

    return $session->privilege->insufficient unless $self->canView;
    
    $var->{ 'form_start'     } 
        = WebGUI::Form::formHeader( $session, {
            action  => $self->getUrl('func=searchTickets;action=search;'),
            extras  => q{id="searchForm"}
        });
    $var->{ 'form_end'       } = WebGUI::Form::formFooter( $session );
    
    $var->{ 'form_submit'    }
        = WebGUI::Form::submit( $session, {
            name        => "submit",
            value       => "Save",
        });
    
    $var->{ 'form_keyword'  }
        = WebGUI::Form::Text( $session, {
            name   => "keyword",
            extras => q{class="search_element"},
        });

    tie my %status, "Tie::IxHash";
    %status = (""=>"Any",%{$self->getStatus});
    $var->{'form_status'    }
        = WebGUI::Form::SelectBox( $session, {
            name    => "ticketStatus",
            options => \%status,
            extras => q{class="search_element"},
        });

    tie my %scope, "Tie::IxHash";
    %scope = ("this"=>"This Help Desk","all"=>"All Tickets");
    $var->{'form_scope'    }
        = WebGUI::Form::SelectBox( $session, {
            name    => "scope",
            options => \%scope,
            extras => q{class="search_element"},
        });

    $var->{'form_assignedTo'}
        = WebGUI::Form::SelectBox( $session, {
            name    => "assignedTo",
            options => $self->_getUsersHash("assignedTo",{""=>"Any","unassigned"=>"unassigned" }),
            extras => q{class="search_element"},
        });

    $var->{'form_assignedBy'}
        = WebGUI::Form::SelectBox( $session, {
            name    => "assignedBy",
            options => $self->_getUsersHash("assignedBy"),
            extras => q{class="search_element"},
        });

    $var->{'form_createdBy'}
        = WebGUI::Form::SelectBox( $session, {
            name    => "createdBy",
            options => $self->_getUsersHash("createdBy"),
            extras => q{class="search_element"},
        });

    $var->{'form_ticketId'}
        = WebGUI::Form::Text( $session, {
            name => "ticketId",
            extras => q{class="search_element"},
        });

    $var->{'form_dateStart'}
        = WebGUI::Form::Date( $session, {
            name   => "dateStart",
            noDate => 1,
            extras => q{class="search_element"},
        });

    $var->{'form_dateEnd'}
        = WebGUI::Form::Date( $session, {
            name   => "dateEnd",
            noDate => 1,
            extras => q{class="search_element"},
        });


    #Build meta fields
    my @metaFieldsLoop = ();
    foreach my $field (@{$self->getHelpDeskMetaFields({searchOnly=>1})}) {
        my $fieldId = $field->{fieldId};
        my $props = {
            name         => "field_".$fieldId,
			options	     => qq{|Any\n}.$field->{possibleValues},
            fieldType    => $field->{dataType},
            defaultValue => "",
            extras => q{class="search_element"},
        };
		my $formField = WebGUI::Form::DynamicField->new($session,%{$props})->toHtml;
        $var->{'form_meta_'.$fieldId} = $formField;
        push(@metaFieldsLoop,{
            form_meta           => $formField,
            form_meta_name      => "meta_".$fieldId,
            form_meta_label     => $field->{label},
        });
	}

    $var->{'meta_loop'     } = \@metaFieldsLoop;
    $var->{'hasMetaFields' } = scalar(@metaFieldsLoop);

    $var->{'url_pageData'  } = $self->getUrl('func=searchTickets;');

    # Add meta fields
    my $metafields   = $self->getHelpDeskMetaFields({returnHashRef => 1});
    for my $fieldId ( keys %{$metafields} ) {
        if ( $metafields->{$fieldId}->{showInList} ) {
            push @{$var->{meta_fields}}, {
                key     => "metadata_" . $fieldId,
                label   => $metafields->{$fieldId}->{label},
                sortable=> 0, # $metafields->{$fieldId}->{sortable},
            };
        }
    }

    return $self->processTemplate($var, $self->searchTemplateId);
}

#-------------------------------------------------------------------
sub www_searchTickets {
    my $self        = shift;
    my $session     = $self->session;
    my $form        = $session->form;
    my $db          = $session->db;

    return $session->privilege->insufficient unless $self->canView;
    
    #We are returning JSON
    $session->response->content_type( 'application/json' );
    
    # Determine which metadata fields we need to send
    my $metafields   = $self->getHelpDeskMetaFields({returnHashRef => 1});
    for my $fieldId ( keys %{$metafields} ) {
        if ( !$metafields->{$fieldId}->{showInList} ) {
            delete $metafields->{$fieldId};
        }
    }

    #Initialize the page settings
    my $rowsPerPage      = 25;

    my $orderByColumn    = $form->get( 'orderByColumn' ) || "creationDate";
    my $orderByDirection = lc $form->get( 'orderByDirection' ) eq "asc" ? "ASC" : "DESC";
    
    my $startIndex     = $form->get( 'startIndex' ) || 1;
    $rowsPerPage      = $form->get( 'rowsPerPage' ) || 25;
    my $currentPage      = int ( $startIndex / $rowsPerPage ) + 1;

    #Set some initial ticket info
    my $ticketInfo                   = {};        
    $ticketInfo->{'recordsReturned'} = $rowsPerPage;
    $ticketInfo->{'totalRecords'   } = 0; 
    $ticketInfo->{'startIndex'     } = $startIndex;
    $ticketInfo->{'sort'           } = $orderByColumn;
    $ticketInfo->{'dir'            } = $orderByDirection;
    $ticketInfo->{'tickets'        } = [];

    #By default don't return any search results   
    unless ($form->get("action") eq "search") {
        return JSON->new->encode( $ticketInfo );
    }

    #Process Search Form
    my $ticketId   = $form->process("ticketId");
    my $keyword    = $form->process("keyword");
    my $status     = $form->process("ticketStatus","selectBox");
    my $scope      = $form->process("scope","selectBox");
    my $assignedTo = $form->process("assignedTo","selectBox");
    my $assignedBy = $form->process("assignedBy","selectBox");
    my $createdBy  = $form->process("createdBy","selectBox");
    my $dateStart  = $form->process("dateStart","date");
    my $dateEnd    = $form->process("dateEnd","date");

    #$session->log->warn("Assigned by: $assignedBy");

    #Initialize the query settings
    my @whereClause   = ();
    my @whereData     = ();
    
    #Ticket Id is a special case.  If the user enters a ticket Id, just return the ticket regardless of scope
    if($ticketId) {
        push(@whereClause,"ticketId=?");
        push(@whereData,$ticketId);
    }
    else {
        #Process all other search requests as a limiting search
        #Scope
        unless ($scope eq "all") {
            push(@whereClause,"parentId=?");
            push(@whereData,$self->getId);
        }
        #Keyword
        if($keyword ne "") {
            push(
                @whereClause,
                q{ (lower(synopsis) like ? or lower(title) like ? or lower(keywords) like ? or lower(solutionSummary) like ?)}
            );
            $keyword = "%".lc($keyword)."%";
            push(@whereData,$keyword,$keyword,$keyword,$keyword);
        }
        #Status
        if($status ne "") {
            push(@whereClause,"ticketStatus=?");
            push(@whereData,$status);
        }
        #Assigned To
        if($assignedTo ne "") {
            if($assignedTo eq "unassigned") {
                push(@whereClause,"assignedTo is NULL");
            }
            else {
                push(@whereClause,"assignedTo=?");
                push(@whereData,$assignedTo);
            }
        }
        #Assigned By
        if($assignedBy ne "") {
            push(@whereClause,"assignedBy=?");
            push(@whereData,$assignedBy);
        }
        #Created By
        if($createdBy ne "") {
            push(@whereClause,"createdBy=?");
            push(@whereData,$createdBy);
        }
        #Start Date
        if($dateStart ne "") {
            my ($dayStart, $dayEnd ) = $session->datetime->dayStartEnd($dateStart);
            push(@whereClause,"creationDate >= ?");
            push(@whereData,$dayStart);
        }
        #Date Started / Date Ended
        if($dateEnd ne "") {
            my ($dayStart, $dayEnd ) = $session->datetime->dayStartEnd($dateEnd);
            push(@whereClause,"creationDate <= ?");
            push(@whereData,$dayEnd);
        }

        my $metaFields = $self->getHelpDeskMetaFields({searchOnly=>1});
        if(scalar(@{$metaFields})) {
            foreach my $field (@{$metaFields}) {
                my $fieldId    = $field->{fieldId};
                my $fieldName  = "field_".$fieldId;
                my $fieldValue = $form->process($fieldName,$field->{dataType});
                if($fieldValue ne "") {
                    my $columnName = $db->dbh->quote_identifier($fieldName);
                    push(@whereClause,"$columnName = ?");
                    push(@whereData,$fieldValue);
                }
            }
        }
    }

    #Always check private tickets
    unless ($self->canEdit) {    
        my $userId     = $session->user->userId;
        push(@whereClause,qq{(isPrivate=0 || (isPrivate=1 && (assignedTo=? || createdBy=?)))});
        push(@whereData,$userId,$userId);
    }

    #SELECT id, body, MATCH (title,body) AGAINST
    #-> ('Security implications of running MySQL as root') AS score
    #-> FROM articles WHERE MATCH (title,body) AGAINST
    #-> ('Security implications of running MySQL as root');
    #my $match  =
    my $orderByClause = $orderByColumn." ".$orderByDirection;
    my $where         = "";
    my $privateClause = "";
    if(scalar(@whereClause)) {
        $where .= qq{where };
        $where .= join(" and ",@whereClause);
    }
       
    my $sql  = qq{
        select
            assetId,
            ticketId,
            url,
            title,
            createdBy,
            creationDate,
            assignedTo,
            ticketStatus,
            lastReplyDate,
            lastReplyBy,
            karmaRank
        from
            Ticket_searchIndex
        $where
        order by
            $orderByClause
    };
    
    #$session->log->warn($sql);

    my $p = WebGUI::Paginator->new( $session, '', $rowsPerPage, 'pn', $currentPage );
    $p->setDataByQuery($sql,undef,undef,\@whereData);

    #Set the number of records returned
    $ticketInfo->{'totalRecords'} = $p->getRowCount;
    
    for my $record ( @{ $p->getPageData } ) {
        my $ticket  = WebGUI::Asset->newById($session, $record->{'assetId'});

        my $lastReplyBy = $record->{'lastReplyBy'};
        if ($lastReplyBy) {
           $lastReplyBy = WebGUI::User->new($session,$lastReplyBy)->username;
        }

        # Populate the required fields to fill in
        my $lastReplyDate = $record->{'lastReplyDate'};
        if($lastReplyDate) {
            $lastReplyDate = $session->datetime->epochToHuman($lastReplyDate,"%y-%m-%d @ %H:%n %p");
        }
        
        # Populate the required fields to fill in
        if($record->{'assignedTo'}) {
            $record->{'assignedTo'} = WebGUI::User->new($session,$record->{'assignedTo'})->username;
        }
        else {
            $record->{'assignedTo'} = "unassigned";
        }
        my %fields      = (
            ticketId      => $record->{'ticketId'},
            url           => $record->{'url'},
            title         => $record->{'title'},
            createdBy     => WebGUI::User->new($session,$record->{'createdBy'})->username,
            creationDate  => $session->datetime->epochToSet($record->{'creationDate'}),
            assignedTo    => $record->{'assignedTo'},
            ticketStatus  => $self->getStatus($record->{'ticketStatus'}),
            lastReplyDate => $lastReplyDate,
            lastReplyBy   => $lastReplyBy,
            lastReplyById => $record->{'lastReplyBy'},
            karmaRank     => sprintf("%.2f",$record->{karmaRank}),
        );

        # Add metadata fields we should show in the list
	my $metadata = $ticket->getTicketMetaData( );
        for my $fieldId (keys %{$metafields}) {   
            my $field   = $metafields->{ $fieldId };
	    $fields{ "metadata_" . $fieldId } = $metadata->{ $fieldId };
            # look for list fields that require mapped output
	    #   ideally this mapping would be done elsewhere, but I am putting it here
	    #   to avoid breaking anything...
	    for my $checkType ( qw/CheckList ComboBox HiddenList Date DateTime
			           RadioList SelectBox SelectList/ ) {
	        if( $metafields->{$fieldId}{dataType} eq $checkType ) {
		    # make the object and get the value
		    my $props = {
			name         => "field_".$fieldId,
				    value        => $metadata->{$fieldId},
				    defaultValue => undef,
				    options      => $metafields->{$fieldId}->{possibleValues},
			fieldType    => $metafields->{$fieldId}->{dataType},
		    };
		    $fields{ "metadata_" . $fieldId } =
		             WebGUI::Form::DynamicField->new($session,%{$props})->getValueAsHtml;
		    last;
		}
	    }
        }

        push @{ $ticketInfo->{ tickets } }, \%fields;
    }
    
    $session->response->content_type( 'application/json' );
    return JSON->new->encode( $ticketInfo );
}

#----------------------------------------------------------------------------

=head2 www_subscribe ( ) 

User friendly method that subscribes the user to the ticket (doesn't return JSON)

=cut

sub www_subscribe {
    my $self      = shift;

    return $self->session->privilege->insufficient  unless $self->canSubscribe;
    
    $self->www_toggleSubscription;
    return "";
}

#----------------------------------------------------------------------------

=head2 www_toggleSubscription ( ) 

Subscribes or unsubscribes the user from the help desk returning the opposite text

=cut

sub www_toggleSubscription {
    my $self      = shift;
    my $session   = $self->session;
    my $i18n      = $self->i18n;

    #Create the subscription group if it doesn't yet exist
    my $group  = $self->getSubscriptionGroup();    
    my @errors = ();

    $session->response->content_type( 'application/json' );
   
    unless ($self->canSubscribe) {
        push(@errors,'You do not have permission to subscribe to this Help Desk');
    }

    if(scalar(@errors)) {    
        return JSON->new->encode({
            hasError =>"true",
            errors   =>\@errors
        });
    }

    my $returnStr = "";
    if($self->isSubscribed) {
        #unsubscribe the user
        $group->deleteUsers([$session->user->userId]);
        #return the subscribe text (opposite)
        $returnStr = $i18n->get("subscribe_link");
    }
    else {
        #subscribe the user
        $group->addUsers([$self->session->user->userId]);
        #return the unsubscribe test (opposite)
        $returnStr = $i18n->get("unsubscribe_link");
    }

    #Find the ticket subscription information if an assetId is passed in
    my $ticketMsg = "";
    my $assetId   = $session->form->get("assetId");
    if($assetId) {
        my $ticket = WebGUI::Asset->newById($session,$assetId);
        $ticketMsg = $ticket->getSubscriptionMessage;
    }

    return "{ message : '$returnStr', ticketMsg : '$ticketMsg' }";
}

#----------------------------------------------------------------------------

=head2 www_unsubscribe ( ) 

User friendly method that subscribes the user to the ticket (doesn't return JSON)

=cut

sub www_unsubscribe {
    my $self      = shift;

    return $self->session->privilege->insufficient  unless $self->canSubscribe;
    
    $self->www_toggleSubscription;
    return "";
}

1;

