package WebGUI::Asset::Ticket;

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

use Moose;
use WebGUI::Definition::Asset;
use JSON;
extends 'WebGUI::Asset';
use WebGUI::Workflow::Instance;


my $ratingUrl       = "wobject/HelpDesk/rating/";

#-------------------------------------------------------------------
define assetName  => [ 'assetName', 'Asset_Ticket' ];
define tableName  => 'Ticket';

property storageId => (
    fieldType    => "file",
    defaultValue => undef,
);
property ticketId => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property assigned => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property ticketStatus => (
    fieldType    => "selectBox",
    defaultValue => "pending"
);
property isPrivate => (
    fieldType    => "yesNo",
    defaultValue => 0
);
property assignedTo => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property assignedBy => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property dateAssigned => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property comments => (
    noFormPost   => 1,
    fieldType    => "hidden",
    serialize    => 1,
    defaultValue => [],
);
property solutionSummary => (
    fieldType    => "hidden",
    defaultValue => undef,
);
property averageRating => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => 0,
);
property lastReplyDate => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property lastReplyBy => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property resolvedBy => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property resolvedDate => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property karma => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property karmaScale => (
    fieldType    => "hidden",
    defaultValue => undef,
);
property karmaRank => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef
);
property subscriptionGroup => (
    noFormPost   => 1,
    fieldType    => "hidden",
    defaultValue => undef,
);


#-------------------------------------------------------------------
sub canAdd {
    my $class   = shift;
    my $session = shift;
    my $asset   = $session->asset;

    #Tickets can only be added to HelpDesk classes
    unless (ref $asset eq "WebGUI::Asset::Wobject::HelpDesk") {
        return 0;
    }
    return $session->user->isInGroup($asset->groupToPost);
}

#-------------------------------------------------------------------
# Whether or not the user has privilege to assign this ticket to someone else
sub canAssign {
    my $self    = shift;
    my $userId  = shift || $self->session->user->userId;
    
    return $self->canEdit($userId);
}

#-------------------------------------------------------------------
# Whether or not the user has privilege to change the status of a ticket
sub canChangeStatus {
    my $self       = shift;
    my $session    = $self->session;
    my $userId     = shift || $session->user->userId;
    my $assignedTo = $self->assignedTo;
    
    return (
        $self->canEdit($userId)
        ||  $userId eq $assignedTo
        || WebGUI::User->new($session,$userId)->isInGroup($self->getParent->groupToChangeStatus)
    );
}

#-------------------------------------------------------------------

=head2 canEdit

Determine if the user has permission to edit the help desk ticket

=head3 userId

User to check edit privileges of

=head3 ignoreNew

If this flag is set, canEdit will ignore the new conditions even if the ticket being submitted is new.

=cut

sub canEdit {
    my $self      = shift;
    my $session   = $self->session;
    my $userId    = shift || $session->user->userId;
    my $form      = $self->session->form;
    my $user      = WebGUI::User->new( $session, $userId );
    my $func      = $form->get("func");
    my $assetId   = $form->get("assetId");
    my $ignoreNew = shift;
    
    # Handle adding new tickets
    if (!$ignoreNew
        && $userId eq $session->user->userId
        && ($func eq "add" || ( $func eq "editSave" && $assetId eq "new" ))
    ){
        return $self->canAdd($session);
    }

    return $self->getParent->canEdit( $userId,$ignoreNew );
}

#-------------------------------------------------------------------
# Whether or not the user has privilege to update this ticket
sub canPost {
    my $self    = shift;
    my $userId  = shift || $self->session->user->userId;
    
    my $ownerId    = $self->createdBy;
    my $assignedTo = $self->assignedTo;

    return 1 if $self->canUpdate($userId);
    return $self->getParent->canPost($userId);

}

#-------------------------------------------------------------------
# Whether or not the user has privilege to update this ticket
sub canUpdate {
    my $self    = shift;
    my $userId  = shift || $self->session->user->userId;
    
    my $ownerId    = $self->createdBy;
    my $assignedTo = $self->assignedTo;

    return ($userId eq $ownerId || $userId eq $assignedTo || $self->canEdit($userId));
}


#-------------------------------------------------------------------
sub canView{
    my $self    = shift;
    my $userId  = shift || $self->session->user->userId;
    
    #Handle private cases
    if($self->isPrivate) {
        return 1 if($self->canUpdate($userId));
        return 0;
    }
    return $self->getParent->canView($userId);
}

#-------------------------------------------------------------------
sub commit {
	my $self    = shift;
    my $session = $self->session;
    my $parent  = $self->getParent;
    my $i18n    = $self->i18n;

	$self->SUPER::commit;
    
    my $msg = $i18n->get("update_ticket_message");
    
    #Award karma for new posts
	if ($self->creationDate == $self->revisionDate) {
        my $karmaPerPost = $parent->karmaPerPost;
		if ($parent->karmaIsEnabled && $karmaPerPost ){
			my $u = WebGUI::User->new($session, $self->createdBy);
			$u->karma($karmaPerPost, $self->getId, "Help Desk post");
		}
        $msg = $i18n->get("new_ticket_message");
	}
    #Send out the message
    $self->notifySubscribers({
        content         =>$msg,
        includeMetaData =>1,
        user            =>WebGUI::User->new($session,$self->ownerUserId)
    }) unless ($self->shouldSkipNotification);

}

#-------------------------------------------------------------------
sub createAdHocMailGroup {
	my $self  = shift;

	my $group = WebGUI::Group->new($self->session, "new");

	$group->name($group->getId);
	$group->description("AdHoc Mail Group for ticket ".$self->getId);
	$group->isEditable(0);
	$group->showInForms(0);
    $group->isAdHocMailGroup(1);
	$group->deleteGroups([3]); # admins don't want to be auto subscribed to this thing

    return $group;
}

#-------------------------------------------------------------------

=head2 getAverageRatingImage

   This method returns the average rating image based on the rating passed in

=cut

sub getAverageRatingImage {
	my $self   = shift;
    my $rating = shift || $self->averageRating;
    return  $self->session->url->extras($ratingUrl."0.png") unless ($rating);
    #Round to one digit integer
    my $imageId = int(sprintf("%1.0f", $rating));
    return $self->session->url->extras($ratingUrl.$imageId.".png");
}

#-------------------------------------------------------------------

=head2 getAutoCommitWorkflowId

    Returns the autocommit workflow for this Ticket

=cut

sub getAutoCommitWorkflowId {
	my $self = shift;
	return $self->getParent->approvalWorkflow;
}

#-------------------------------------------------------------------

=head2 getCommonDisplayVars (  )

Returns common variables used to display details about a ticket.

=cut

sub getCommonDisplayVars {
	my $self    = shift;
    my $session = $self->session;
    my $parent  = $self->getParent;
    my $var     = $self->get;
    my $ticketStatus;

    my $createdBy=  WebGUI::User->new($session,$var->{'createdBy'});

    my $assignedTo= ($var->{'assignedTo'})
        ? WebGUI::User->new($session,$var->{'assignedTo'})
        : undef
        ;

    my $assignedBy= ($var->{'assignedBy'})
        ? WebGUI::User->new($session,$var->{'assignedBy'})
        : undef
        ;
    
    my $resolvedBy= ($var->{'resolvedBy'})
        ? WebGUI::User->new($session,$var->{'resolvedBy'})
        : undef
        ;
    
    $ticketStatus = $parent->getStatus($self->ticketStatus);

    #Format Data for Display
    $var->{'ticketStatus'     } = $ticketStatus;
    $var->{'isAssigned'       } = $self->assigned;
    $var->{'assignedTo'       } = $assignedTo ? $assignedTo->username : 'unassigned';
    $var->{'assignedToUrl'    } = $assignedTo ? $assignedTo->getProfileUrl : 0 ;
    $var->{'assignedBy'       } = $assignedBy ? $assignedBy->username : '' ;
    $var->{'assignedByUrl'    } = $assignedBy ? $assignedBy->getProfileUrl : 0 ;
    $var->{'resolvedBy'       } = $resolvedBy ? $resolvedBy->username : '' ;
    $var->{'resolvedByUrl'    } = $resolvedBy ? $resolvedBy->getProfileUrl : 0 ;
    $var->{'createdBy'        } = $createdBy->username;
    $var->{'createdByUrl'     } = $createdBy->getProfileUrl;
    $var->{'creationDate'     } = $session->datetime->epochToSet($var->{'creationDate'});
    $var->{'dateAssigned'     } = $session->datetime->epochToSet($var->{'dateAssigned'});
    $var->{'isPrivate'        } = $self->isPrivate;
    $var->{'solutionSummary'  } = $self->solutionSummary;
    
    #Display metadata
    my $metafields   = $parent->getHelpDeskMetaFields({returnHashRef => 1});
    my $metadata     = $self->getTicketMetaData;
    my @metaDataLoop = ();
    foreach my $fieldId (keys %{$metafields}) {   
        my $props = {
            name         => "field_".$fieldId,
			value        => $metadata->{$fieldId},
			defaultValue => undef,
			options	     => $metafields->{$fieldId}->{possibleValues},
            fieldType    => $metafields->{$fieldId}->{dataType},
        };
        my $fieldValue = WebGUI::Form::DynamicField->new($session,%{$props})->getValueAsHtml;
        $var->{'meta_'.$fieldId} = $fieldValue;
        push(@metaDataLoop, {
            "meta_field_id"    => $fieldId,
            "meta_field_label" => $metafields->{$fieldId}->{label},
            "meta_field_value" => $fieldValue,
        });
    }
    $var->{'meta_field_loop'} = \@metaDataLoop;
    return $var;
}

#-------------------------------------------------------------------------

=head2 getEditTemplate ( )

Get the template to edit this ticket

=cut

sub getEditTemplateId {
    my ( $self ) = @_;
    return $self->getParent->editTicketTemplateId;
}

override 'getEditTemplate' => sub {
    my ( $self ) = @_;
    my $session = $self->session;
    my ( $form ) = $session->quick(qw{ form });
    my $parent  = $self->getParent;

    # Prepare the template variables
    my $var         = {};
    $var->{isAdmin} = $self->canEdit($session->user->userId,1);

    # Process errors if any
    if ( $session->stow->get( 'editFormErrors' ) ) {
        for my $error ( @{ $session->stow->get( 'editFormErrors' ) } ) {
            push @{ $var->{ errors } }, {
                error       => $error,
            };
        }
    }

    if ( $form->get('func') eq "add" ) {
        $var->{ isNewTicket }    = 1;
    }
    
    # Generate the form
    if ($form->get("func") eq "add"  || ($form->get("func") eq "editSave" && $form->get("assetId") eq "new")) {
        $var->{ form_start  }
            = WebGUI::Form::formHeader( $session, {
                action      => $parent->getUrl('func=addSave;assetId=new;className='.__PACKAGE__),
            })
            . WebGUI::Form::hidden( $session, {
                name        => 'ownerUserId',
                value       => $session->user->userId,
            })
            . WebGUI::Form::hidden( $session, {
                name        => 'ticketId',
                value       => "",
            })
            ;
    }
    else {
        $var->{ form_start  } 
            = WebGUI::Form::formHeader( $session, {
                action      => $self->getUrl('func=editSave'),
            })
            . WebGUI::Form::hidden( $session, {
                name        => 'ownerUserId',
                value       => $self->ownerUserId,
            })
            . WebGUI::Form::hidden( $session, {
                name        => 'ticketId',
                value       => $self->ticketId,
            })
            ;
    }

    $var->{ form_start } 
        .= WebGUI::Form::hidden( $session, {
            name        => "proceed",
            value       => "showConfirmation",
        });

    $var->{ form_end } = WebGUI::Form::formFooter( $session );
    
    $var->{ form_submit }
        = WebGUI::Form::submit( $session, {
            name        => "save",
            value       => "Save",
        });

    $var->{ form_title  }
        = WebGUI::Form::Text( $session, {
            name        => "title",
            value       => ( $form->get("title") || $self->title ),
        });
    

    $var->{ form_synopsis }
        = WebGUI::Form::HTMLArea( $session, {
            name        => "synopsis",
            value       => ( $form->get("synopsis") || $self->synopsis ),
            richEditId  => $self->getParent->richEditIdPost,
            height      => 300,
        });

    $var->{ form_attachment }
        = WebGUI::Form::file($session, {
            name            =>"storageId",
            value           =>$self->storageId,
            maxAttachments  =>5,
            deleteFileUrl   =>$self->getUrl("func=deleteFile;filename=")
        });
    
    $var->{ form_isPrivate }
        = WebGUI::Form::yesNo( $session, {
            name        => "isPrivate",
            value       => ( $form->get("isPrivate") || $self->isPrivate ),
        });
    
    $var->{ form_keywords }
        = WebGUI::Form::Text( $session, {
            name        => "keywords",
            value       => ( $form->get("keywords") || $self->keywords ),
        });

    $var->{ useKarma        } = $parent->karmaIsEnabled;
    $var->{ form_karmaScale }
        = WebGUI::Form::Integer( $session, {
            name        => "karmaScale",
            value       => ( $form->get("karmaScale") || $self->karmaScale || $parent->defaultKarmaScale ),
        });

    $var->{ form_solutionSummary }
        = WebGUI::Form::textarea( $session, {
            name        => "solutionSummary",
            value       => ( $form->get("solutionSummary") || $self->solutionSummary )
        });

    $var->{ form_ticketStatus }
        = WebGUI::Form::selectBox( $session, {
            name        => "ticketStatus",
            options     => $parent->getStatus,
            value       => ( $form->get("ticketStatus") || $self->ticketStatus )
        });
    

    #Build meta fields
    my $metadata       = $self->getTicketMetaData;
    my @metaFieldsLoop = ();
    foreach my $field (@{$parent->getHelpDeskMetaFields}) {
        my $fieldId = $field->{fieldId};
        my $name    = "field_$fieldId";
        my $props = {
            name         => $name,
			value        => scalar($metadata->{$fieldId} || $form->get($name)),
			defaultValue => $field->{defaultValues},
			options	     => $field->{possibleValues},
            fieldType    => $field->{dataType},
        };
		my $formField = WebGUI::Form::DynamicField->new($session,%{$props})->toHtml;
        $var->{'form_meta_'.$fieldId} = $formField;
        push(@metaFieldsLoop,{
            form_field           => $formField,
            form_field_name      => "field_".$fieldId,
            form_field_label     => $field->{label},
            form_field_hoverHelp => $field->{hoverHelp},
        });
	}

    $var->{'fields_loop'} = \@metaFieldsLoop;
    $var->{'hasMetaFields' } = scalar(@metaFieldsLoop);

    my $template = super();
    $template->style( $parent->styleTemplateId );
    $template->setParam( %$var );
    return $template;
};

#------------------------------------------------------------------

=head2 getHistory (  )

Returns an arrayref of hash references of the tickets history.

=cut

sub getHistory {
	my $self       = shift;
    my $dbh  = $self->session->db->dbh;
    
    my $sql = q{
        select
            dateStamp as 'history_date_epoch',
            FROM_UNIXTIME(dateStamp,'%c/%e/%Y<br />%l:%i %p') as 'history_date',
            actionTaken as 'history_action',
            username as 'history_user',
            users.userId as 'history_userId'
        from
            Ticket_history
            left join users using (userId)
        where assetId=?
        order by dateStamp desc
    };

    my $arrRef = $dbh->selectall_arrayref(
      $sql,
      { Slice => {} },
      $self->getId
    );
    $arrRef = [] unless (defined $arrRef);
    return $arrRef;
}

#-------------------------------------------------------------------

=head2 getImageIcon (  )

Returns the icon passed in from the icon system.  This fuction is used
because $session->icon addtionally adds preset links to these icons.

=cut

sub getImageIcon {
	my $self = shift;
    my $icon = shift || "edit";
    my $text = shift || ucfirst($icon);
    
    my $icon = $self->session->icon->getBaseURL().$icon.".gif";

	return qq{<img src="$icon" style="vertical-align:middle;border: 0px;" alt="$text" title="$text" />};
}

#----------------------------------------------------------------------------
sub getRelatedFilesVars {
    my $self      = shift;
    my $session   = $self->session; 
    my $storageId = shift;
    my $var       = {};

    return $var unless ($storageId);

    #Add Existing Files    
    my @files     = ();
    if($storageId) {
        my $store   = WebGUI::Storage->get($session,$storageId);
        my $fileRef = $store->getFiles;
        foreach my $filename (@{$fileRef}) {
            push(@files, {
                'file_name'       => $filename,
                'file_url'        => $store->getUrl($filename),
                'file_icon_url'   => $store->getFileIconUrl($filename)
            });
        }
    }

    $var->{'hasFiles'  } = scalar(@files);
    $var->{'files_loop'} = \@files;

    return $var;
}

#----------------------------------------------------------------------------

=head2 getStorageLocation ( options ) 

Properly posts a file to it's storage location

=cut

sub getStorageLocation {
    my $self      = shift;
    
    my $storageId = $self->storageId;
    my $store     = undef;

    if ($storageId) {
        $store = WebGUI::Storage->get($self->session,$storageId);
    }
    else {
        #No storageId - create one and update the asset
        $store = WebGUI::Storage->create($self->session);
        $self->update({ storageId=>$store->getId });
    }
    
    return $store;
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
        $group = $self->getParent->createSubscriptionGroup($self,"ticket",$self->ticketId);
    }
    return $group;
}

#-------------------------------------------------------------------
sub getSubscriptionMessage {
	my $self  = shift;
    my $i18n  = $self->i18n;

    return $i18n->get("unsubscribe_link") if($self->isSubscribed);
    return $i18n->get("subscribe_link");
}

#-------------------------------------------------------------------

=head2 getTicketMetaData

Returns metadata properties as a hashref.

=head3 key

If specified, returns a single value for the key specified.

=cut

sub getTicketMetaData {
	my $self    = shift;
	my $key     = shift;
    my $session = $self->session;
	
    unless ($self->{_metadata}) {
       $self->{_metadata} = $session->db->buildHashRef("select fieldId, value from Ticket_metaData where assetId=?",[$self->getId]);
    }
    
    if(defined $key) {
       return $self->{_metadata}->{$key};
    }
    return $self->{_metadata};
}

#----------------------------------------------------------------------------

=head2 hasKarma ( ) 

determines whether or not the user logged in has the amount of karma that was
passed in.

=cut

sub hasKarma {
    my $self        = shift;
    my $amount      = shift;    

    return ($self->session->user->karma >= $amount);
}


#-------------------------------------------------------------------
sub i18n {
	my $self    = shift;
    my $session = $self->session;
    
    unless ($self->{_i18n}) { 
        $self->{_i18n} = WebGUI::International->new($session, "Asset_Ticket");
    }
    return $self->{_i18n};
}

#-------------------------------------------------------------------

=head2 isReply (  )

Returns a boolean indicating whether there are comments on this ticket.

=cut

sub isReply {
    my $self     = shift;
    my $comments = $self->comments;
    return (scalar(@$comments) > 1);
}

#-------------------------------------------------------------------

=head2 isSubscribed ( [userId] )

Returns a boolean indicating whether the user is subscribed to the ticket or help desk.

=cut

sub isSubscribed {
    my $self   = shift;
    my $userId = shift;

    #Return true user is in the help desk subscription group
    return 1 if ($self->getParent->isSubscribed($userId));
    #Return false if the subscription group is not set
    return $self->isSubscribedToTicket($userId);
}

#-------------------------------------------------------------------

=head2 isSubscribedToTicket ( [userId]  )

Returns a boolean indicating whether the user is subscribed to the ticket

=cut

sub isSubscribedToTicket {
    my $self    = shift;
    my $userId  = shift;

    my $user    = undef;
    if($userId) {
        $user = WebGUI::User->new($self->session,$userId)
    }
    else {
        $user   = $self->session->user;
    }

    #Return false if the subscription group is not set
    return 0 unless ($self->subscriptionGroup);
	return $user->isInGroup($self->subscriptionGroup);	
}

#----------------------------------------------------------------------------

=head2 logHistory ( actionTaken [,user] ) 

log an event

=cut

sub logHistory {
    my $self        = shift;
    my $session     = $self->session;
    my $actionTaken = shift;
    my $user        = shift || $session->user;

    my $props   = {};
    $props->{'historyId'  } = "new";
    $props->{'actionTaken'} = $actionTaken;
    $props->{'dateStamp'  } = time();
    $props->{'userId'     } = $user->userId;
    $props->{'assetId'    } = $self->getId;

    $session->db->setRow("Ticket_history","historyId",$props);
}

#-------------------------------------------------------------------

=head2 makeAnchorTag ( url, text, [ title ] )

got tired of typing this over and over...

=cut

sub makeAnchorTag {
    my $url = shift;
    my $text = shift;
    my $title = shift || '';

    if( $title ne '' ) {
        return q{<a href='} . $url . q{' title='} . $title . q{'>} . $text . '</a>';
    } else {
        return q{<a href='} . $url . q{'>} . $text . '</a>';
    }
}

#-------------------------------------------------------------------

=head2 notifySubscribers ( props )

Send notifications to the help desk and ticket subscribers

=head3 properties

properties to pass in for mail

=head4 user

=head4 from

=head4 subject

=head4 content

=cut

sub notifySubscribers {
    my $self           = shift;
    my $props          = shift;
    my $session        = $self->session;
    my $parent         = $self->getParent;
    my $user           = $props->{user} || $session->user;

    my $domain         = $parent->mailAddress;
    $domain            =~ s/.*\@(.*)/$1/;
   
    #Set the messageId
    $props->{'messageId'} = "ticket-".$self->getId.'@'.$domain;
    if ($props->{newTicket}) {
        delete $props->{newTicket};
    }
    else {
        $props->{'replyId'} = $props->{'messageId'};
    }

    #Figure out who to send the message to based on subscription groups
    my $helpDeskSubGroup = $parent->getSubscriptionGroup;
    my $ticketSubGroup   = $self->getSubscriptionGroup;
    
    #Create an Ad Hoc Mail group containing all the users that are subscribed to the ticket but not the Help Desk;
    my $helpDeskGroup = $helpDeskSubGroup;
    my $ticketGroup   = $self->createAdHocMailGroup;
    $ticketGroup->addUsers($ticketSubGroup->getUsersNotIn($helpDeskSubGroup->getId,1));

    #Send messages to the right people for private tickets - the ticketGroup will only have users that can view the ticket
    if($self->isPrivate) {
        my $users      = $helpDeskGroup->getUsers(1);
        my @validUsers = ();
        foreach my $userId (@{$users}) {
            if($self->canView($userId)) {
                push(@validUsers,$userId);
            }
        }
        $helpDeskGroup = $self->createAdHocMailGroup;
        $helpDeskGroup->addUsers(\@validUsers);
    }

    #Set who the message is from
    $props->{from} = $user->profileField("email");

    #use Data::Dumper;
    #$session->log->warn(Dumper($ticketGroup->getUsers));
    #$session->log->warn(Dumper($helpDeskGroup->getUsers));

    #Create mail settings for the two emails that need to go out
    my $mailTo = [{
        groupId        => $helpDeskGroup->getId,
        subscribeUrl   => $parent->getUrl("func=toggleSubscription"),
        unsubscribeUrl => $parent->getUrl("func=toggleSubscription"),
    },{
        groupId        => $ticketGroup->getId
    }];

    #Send the message to everyone in the Help Desk Subscription Group and those subscribed to the Ticket that are not subscribed to the Help Desk
    foreach my $mailSettings (@{$mailTo}) {
        #Append constants to distinct mail settings
        %{$mailSettings} = (%{$props},%{$mailSettings});
        #Send Mail
        $self->sendMail($mailSettings);
    }
}


#----------------------------------------------------------------------------

=head2 postComment ( comment, options ) 

Posts a comment to the ticket

=head3 comment

a macro negated comment to post

=head3 options

optional things which can affect how the comment is posted

=head4 rating

post rating

=head4 solution

solution summary

=head4 user

user that is posting the comment.  Defaults to $self->session->user

=head4 status

this comment was related to a status change by a user. Send out a special notification

=cut

sub postComment {
    my $self      = shift;
    my $comment   = shift;
    my $options   = shift;
    my $i18n      = $self->i18n;
    my $session  = $self->session;
    
    my $rating      = $options->{rating} || 0;
    my $solution    = $options->{solution};
    my $user        = $options->{user} || $session->user;
    my $status      = $options->{status};
    my $closeTicket = $options->{closeTicket};
    my $now         = time();
    
    my $parent      = $self->getParent;
    my $useKarma    = $parent->karmaIsEnabled;

    return 0 if ($comment eq "");

    my $comments  = $self->comments;    
    my $commentId;
    if( $options->{commentId} && $options->{commentId} ne 'new' ) {
        $commentId = $options->{commentId};
        for my $item ( @$comments ) {
	    if( $item->{id} eq $commentId ) {
	        $item->{comment} = $comment;
	        $item->{rating} = $rating;
	        $item->{data} = $now;
	        $item->{ip} = $session->request->address;
	    }
        }
    } else {
        $commentId = $session->id->generate;
	push @$comments, {
		id          => $commentId,
        alias		=> $user->profileField('alias'),
		userId		=> $user->userId,
		comment		=> $comment,
		rating		=> $rating,
		date		=> $now,
		ip			=> $session->request->address,
	};
    }

    #Recalculate the rating
    my $count = 0;
    my $sum   = 0;
    map { $sum += $_->{rating}; $count++ if($_->{rating} > 0); } @{$comments};    
    #Avoid divide by zero errors
    $count        = 1 unless ($count);
    my $avgRating = $sum/$count;

    #Set the solution summary if it was posted
    if( not $solution ) {
        $solution  = $session->form->process("solution","textarea");
        $solution = WebGUI::HTML::format($solution, 'text');
        WebGUI::Macro::negate(\$solution) if($solution);
    }

    #Update the Ticket.
	$self->update({
        comments         => $comments,
        solutionSummary  => $solution,
        averageRating    => $avgRating,
        lastReplyDate    => $now,
        lastReplyBy      => $user->userId,
    });

    #Award karma
    if($useKarma) {
        my $amount         = $parent->karmaPerPost;
        my $comment        = "Left comment for Ticket ".$self->ticketId;
        $user->karma($amount, $self->getId, $comment);
    }
    
    my $ticketStatus = $self->ticketStatus;
    if($status) {
        #This was a post to change the ticket status so update the comment
        my $statusMessage = $i18n->get("notification_status_message");
        $ticketStatus     = $parent->getStatus($status);
        $comment          = sprintf($statusMessage,$ticketStatus)."<br /><br />".$comment;
    }
    elsif($ticketStatus eq "resolved" || $ticketStatus eq "feedback") {
        #This was a post by a someone after a ticket was markes as resolved or feedback requested - repoen it
        my $status = "pending";
        #The closed button was clicked so close the ticket
        $status    = "closed" if($ticketStatus eq "resolved" && $closeTicket);
        $self->setStatus($status,$user);
        my $statusMessage = $i18n->get("notification_status_message");
        #Ticket status was changed so update the comment
        $ticketStatus     = $parent->getStatus($self->ticketStatus);
        $comment          = sprintf($statusMessage,$ticketStatus)."<br /><br />".$comment;
    }
    
    #Send notifications to subscribers
    $self->notifySubscribers({ content=>$comment });

}


#----------------------------------------------------------------------------

=head2 processErrors ( ) 

processes an error array and returns a json string

=cut

sub processErrors {
    my $self    = shift;
    my $errors  = shift;    

    my $errorHash = {
        hasError =>"true",
        errors   =>$errors
    };

    return JSON->new->encode( $errorHash );
}


#----------------------------------------------------------------------------

=head2 processPropertiesFromFormPost ( )

Process the asset edit form. 

Make the default title into the file name minus the extention.

=cut

sub processPropertiesFromFormPost {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;
    my $db      = $session->db;
    my $errors  = $self->SUPER::processPropertiesFromFormPost || [];
    my $assetId = $self->getId;
    my $parent  = $self->getParent;
    my $i18n    = $self->i18n;

    if( $form->process('title') eq '' ) {
        push(@{$errors},$i18n->get('title required'));
    }
    if( $form->process('synopsis') eq '' ) {
        push(@{$errors},$i18n->get('synopsis required'));
    }
    #Process the meta data fields
    my @metadata = ();
    foreach my $field (@{$self->getParent->getHelpDeskMetaFields}) {
        my $fieldId    = $field->{fieldId};
        my $fieldValue = $form->process("field_".$fieldId,$field->{dataType});
        if($field->{required} && $fieldValue eq "") {
            push(@{$errors},$field->{label}." is a required field");
        }
        push(@metadata,{
           fieldId => $fieldId,
           value   => $fieldValue,
        });
    }
    
    # Return if errors
    return $errors if @$errors;
    
    ### Passes all checks
    # If this is a new ticket, update the url to include the ticketId
    my $ticketId   = $self->ticketId;
    my $karmaScale = $form->get("karmaScale") || $self->karmaScale || $parent->defaultKarmaScale;
    my $karma      = $self->karma;
    my $historyMsg = "Ticket edited";

    if ( $form->get('assetId') eq "new" ) {
        $ticketId   = $session->db->getNextId("ticketId");
        $historyMsg = "Ticket created";
    }

    #This also inserts the record into the search index table
    # and updates metadata
    $self->update( {
        url           => $session->url->urlize( join "/", $parent->url, $ticketId ),
        ticketId      => $ticketId,
        karmaScale    => $karmaScale,
        karma         => $karma,
        metadata      => [@metadata],
        lastReplyDate => $self->lastModified,
        lastReplyBy   => $self->ownerUserId,
    });


    #Automatically subscribe the user posting the ticket - this also creates the subscription group
    $self->subscribe;
    
    #Log the history
    $self->logHistory($historyMsg);

    #Request Autocommit
    $self->requestAutoCommit;

    # kick off Run On New Ticket workflow
    if ( $form->get('assetId') eq "new" ) {
        if ( my $workflowId = $parent->runOnNewTicket ) {
            WebGUI::Workflow::Instance->create( $session, {
                 workflowId => $workflowId,
                 methodName => 'new',
                 className  => 'WebGUI::Asset::Ticket',
                 parameters => $assetId,
                 priority   => 1,
            } )->start;
        }
    }

    return undef;
}


#-------------------------------------------------------------------

=head2 purge ( )

This method is called when data is purged by the system.
removes collateral data associated with a NewAsset when the system
purges it's data.  This method is unnecessary, but if you have 
auxiliary, ancillary, or "collateral" data or files related to your 
asset instances, you will need to purge them here.

=cut

sub purge {
	my $self    = shift;
    my $session = $self->session;
    my $db      = $session->db;

    #Delete the subscription group
    my $group = WebGUI::Group->new($session, $self->subscriptionGroup);
	$group->delete if ($group);

    #Delete the storage location and all the files.
    if($self->storageId) {
        my $store = WebGUI::Storage->get($session,$self->storageId);
        $store->delete;
    }

    #Delete records from the history table
    $db->write("delete from Ticket_history where assetId=?",[$self->getId]);

    #Delete records from the metadata table
    $db->write("delete from Ticket_metaData where assetId=?",[$self->getId]);

    #Delete records from the searchIndex table
    $db->write("delete from Ticket_searchIndex where assetId=?",[$self->getId]);

	return $self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 sendMail ( props )

Send a mail message from the system

=head3 properties

properties to pass in for mail

=head4 user

user to send mail as 

=head4 from

who the email is from.  Default is the email address of the poster

=head4 subject

subject

=head4 message

fully templated content to set as the message.  If this is passed in the content setting will be ignored.

=head4 content

content to be wrapped in the notification template

=head4 subscribeUrl

subscribe url - default is the ticket subscription url

=head4 unsubscribeUrl

unsubscribe url - default is the ticket unsubscription url

=head4 messageId

a messageId that can be set on the message - default is a unique message id

=head4 replyId

a replyId that can be set on the message - default is no reply id

=head4 groupId

a group to send the message to.  If this is set to and toUser will be ignored

=head4 to

an email address to send the message to.

=head4 toUser

a userId to send the message to (use this in place of to)

=head4 includeMetaData

whether or not to include ticket meta data with the email.  These will be passed in as template variables to the ticket.

=cut

sub sendMail {
    my $self           = shift;
    my $props          = shift;
    my $session        = $self->session;
    my $setting        = $session->setting;
    my $parent         = $self->getParent;
    my $i18n           = $self->i18n;
    my $user           = $props->{user} || $session->user;

    #Don't send emails to the user posting.
    return if($user->userId eq $props->{toUser});

    my $siteurl        = $session->url->getSiteURL();
    my $parentUrl      = $siteurl.$parent->getUrl;
    my $returnAddress  = $setting->get("mailReturnPath");
    my $companyAddress = $setting->get("companyEmail");
    my $listAddress    = $parent->mailAddress;
    my $companyUrl     = $setting->get("companyURL");
    my $companyName    = $setting->get("companyName");
    
    my $from           = $props->{from} || $listAddress    || $companyAddress;
    my $replyTo        = $listAddress   || $returnAddress  || $companyAddress;
    my $sender         = $listAddress   || $companyAddress || $from;
    my $returnPath     = $returnAddress || $sender;

    my $defaultSubUrl  = $self->getUrl("func=toggleSubscription");
    my $subscribeUrl   = $siteurl.($props->{subscribeUrl}   || $defaultSubUrl);
    my $unsubscribeUrl = $siteurl.($props->{unsubscribeUrl} || $defaultSubUrl);
    
    my $listId         = $sender;
    $listId            =~ s/\@/\./;

    #Message
    my $message        = $props->{message};
    unless ($message) {
        my $var            = {};
        if($props->{includeMetaData}) {
            $var = $self->getCommonDisplayVars;
            $var->{'hasMetaData'} = "true";
        }
    
        #Create the template vars for the message
        $var->{'url'                } = $siteurl.$self->getUrl;
        $var->{'username'           } = $user->username;
        $var->{'unsubscribeUrl'     } = $unsubscribeUrl;
        $var->{'unsubscribeLinkText'} = $i18n->echo("unsubscribe");
        $var->{'content'            } = $props->{content};

        #Create the message
        $message   = $self->processTemplate($var, $parent->notificationTemplateId);
    }
    
    #Subject
    my $subject   = $props->{subject} || $parent->mailPrefix.$self->title;
    
    #Set the messageId info
    my $messageId = $props->{messageId} ? "<".$props->{messageId}.">" : "";
    my $replyId   = $props->{replyId}   || "";

    my $mail = WebGUI::Mail::Send->create($self->session, {
        from       => "<".$from.">",
        returnPath => "<".$returnPath.">",
		replyTo    => "<".$replyTo.">",
        to         => $props->{to},
        toUser     => $props->{toUser},
		toGroup    => $props->{groupId},
		subject    => $subject,
		messageId  => $messageId
    });

    $mail->addHeaderField("In-Reply-To", "<".$replyId.">");
    $mail->addHeaderField("References", "<".$replyId.">");
    $mail->addHeaderField("List-ID", $parent->getTitle." <".$listId.">");
    $mail->addHeaderField("List-Help", "<mailto:".$companyAddress.">, <".$companyUrl.">");
    $mail->addHeaderField("List-Unsubscribe", "<".$unsubscribeUrl.">");
    $mail->addHeaderField("List-Subscribe", "<".$subscribeUrl.">");
    $mail->addHeaderField("List-Owner", "<mailto:".$companyAddress.">, <".$companyUrl."> (".$companyName.")");
    $mail->addHeaderField("Sender", "<".$sender.">");
    if ($listAddress eq "") {
        $mail->addHeaderField("List-Post", "No");
    }
    else {
        $mail->addHeaderField("List-Post", "<mailto:".$listAddress.">");
    }
    $mail->addHeaderField("List-Archive", "<".$parentUrl.">");
    $mail->addHeaderField("X-Unsubscribe-Web", "<".$unsubscribeUrl.">");
    $mail->addHeaderField("X-Subscribe-Web", "<".$subscribeUrl.">");
    $mail->addHeaderField("X-Archives", "<".$parentUrl.">");
    $mail->addHtml($message);
    $mail->addFooter;
    $mail->queue;
}


#----------------------------------------------------------------------------

=head2 setStatus ( ticketStatus [,user] ) 

Properly sets the current status of a ticket.

=cut

sub setStatus {
    my $self         = shift;
    my $session      = $self->session;
    my $parent       = $self->getParent;
    my $useKarma     = $parent->karmaIsEnabled;

    my $ticketStatus = shift;
    my $assetStatus  = $self->status;
    my $user         = shift || $session->user;

    return 0 unless $ticketStatus;

    my $updates      = {};

    #Status is approved unless it's closed
    $updates->{'status'} = 'approved';

    #Handle closed tickets
    if($ticketStatus eq "closed") {
        if($useKarma) {
            my $amount     = $parent->karmaToClose;
            my $comment    = "Closed Ticket ".$self->ticketId;
            #Figure out who to give the karma to
            #If the ticket hasn't been resolved, then it is being manually closed.
            my $closedBy = $user;
            #Use resolved by if it's being automatically closed or manually resolved
            if($self->resolvedBy) {
                $closedBy = WebGUI::User->new($session,$self->resolvedBy);
            }
            $closedBy->karma($amount, $self->getId, $comment);
        }
        $updates->{'status'} = "archived";
    }
    elsif ($ticketStatus eq "resolved") {
        $updates->{'resolvedBy'  } = $user->userId;
        $updates->{'resolvedDate'} = time();
    }

    $updates->{'ticketStatus'} = $ticketStatus;

    $self->update($updates);

    #Log the change in status
    $self->logHistory($parent->getStatus($ticketStatus),$user);

    return 1;
}


#----------------------------------------------------------------------------

=head2 setTicketMetaData ( fieldId, value )

fieldId : the id of the field to be set

value : the new value for the field

=cut

sub setTicketMetaData {
	my $self    = shift;
	my $fieldId     = shift;
	my $value     = shift;
    my $session = $self->session;
	
    unless ($self->{_metadata}) {
       $self->getTicketMetaData();  # prime the meta data
    }
    $self->{_metadata}{$fieldId} = $value;
    $self->update( { metadata => [ { fieldId => $fieldId, value => $value } ] } );
}


#----------------------------------------------------------------------------

=head2 setKarmaScale ( ) 

Properly sets the karma scale of a ticket.

=cut

sub setKarmaScale {
    my $self         = shift;
    my $session      = $self->session;
    my $useKarma     = $self->getParent->karmaIsEnabled;
    
    #Don't allow the karma scale to be set unless karma is enabled.
    return 0 unless $useKarma;

    my $karmaScale = shift;
    my $karma      = $self->karma;

    #Don't let karma scale be set to zero
    return 0 unless $karmaScale;

    my $karmaRank = $karma / $karmaScale;

    $self->update({
        karmaScale => $karmaScale,
        karmaRank  => $karmaRank
    });

    #Log the change in status
    $self->logHistory("Difficulty changed to $karmaScale");

    return 1;
}

#----------------------------------------------------------------------------

=head2 subscribe ( ) 

subscribes user to ticket

=cut

sub subscribe {
    my $self      = shift;
    my $userId    = shift || $self->session->user->userId; 

    #Create the subscription group if it doesn't yet exist
    my $group  = $self->getSubscriptionGroup();      
    $group->addUsers([$userId]);
    
    return;
}


#----------------------------------------------------------------------------

=head3 ticketStatusEdit

this function returns an AJAX editable field if the user can change the status

=cut

sub ticketStatusEdit {
    my $self = shift;
    my $session = $self->session;
    my $parent = $self->getParent;
    # if the user can change the status then send an editable field
    if( $self->canChangeStatus ) {
        my $status = $parent->getStatus;
	my $value   = $self->ticketStatus;
        delete $status->{pending} unless $value eq 'pending';
        delete $status->{closed} unless $value eq 'closed';
        delete $status->{feedback} if ! $session->user->isInGroup($parent->groupToChangeStatus);
        return WebGUI::Form::selectBox($session,{
		name    =>"ticketStatus",
                id      =>"ticketStatus_formId",
		options => $status,
		value   => $value,
                extras  => q{class="dyn_form_field" onchange="WebGUI.Ticket.saveTicketStatus(this)"}
	    });
    } else {
        return $self->getParent->getStatus($self->ticketStatus);
    }
}

#----------------------------------------------------------------------------

=head2 transferKarma ( ) 

Properly transfers karma to the ticket and subtracts it from the user.

=cut

sub transferKarma {
    my $self         = shift;
    my $session      = $self->session;
    my $useKarma     = $self->getParent->karmaIsEnabled;
    
    #Don't allow karma to be added unless karma is enabled.
    return 0 unless $useKarma;

    my $amount       = shift;
    my $karma        = $self->karma + $amount;
    my $karmaScale   = $self->karmaScale;
    my $karmaRank    = $karma / $karmaScale;    

    #Update the ticket
    $self->update({
        karma      => $karma,
        karmaRank  => $karmaRank
    });
    
    #subtract the karma from the user
    $session->user->karma(-$amount,$self->getId,"Transferring karma to a ticket.");

    #Log the change in karma
    $self->logHistory("$amount karma transferred");

    return 1;
}

#----------------------------------------------------------------------------

=head2 unsubscribe ( ) 

unsubscribes user from ticket

=cut

sub unsubscribe {
    my $self    = shift;
    my $userId  = shift || $self->session->user->userId;

    #Create the subscription group if it doesn't yet exist
    my $group  = $self->getSubscriptionGroup();      
    $group->deleteUsers([$userId]);

    return;
}

#-------------------------------------------------------------------
sub update {
    my $self       = shift;
    my $session    = $self->session;
    my $db         = $session->db;
    my $parent     = $self->getParent;
	my $properties = shift;

	if (exists $properties->{comments}) {
        my $comments = $properties->{comments};
        $comments = [] unless ($comments);
        if (ref $comments ne 'ARRAY') {
            $comments = eval{JSON->new->decode($comments)};
            if (WebGUI::Error->caught) {
                $comments = [];
            }
        }
        $properties->{comments} = JSON->new->encode($comments);
    }
   
	if (exists $properties->{title}) {
		WebGUI::Macro::negate(\$properties->{title});
		$properties->{menuTitle} = $properties->{title};
	}
	if (exists $properties->{synopsis}) {
		WebGUI::Macro::negate(\$properties->{synopsis});
	}
    if ($properties->{assignedTo} eq "unassigned") {
        $properties->{assignedTo} = "";
    }
    #Karma scale cannot be zero
    if(exists $properties->{karmaScale} && $properties->{karmaScale} == 0) {
        $properties->{karmaScale} = $self->karmaScale || $parent->defaultKarmaScale;
    }
    if ($properties->{karma} || $properties->{karmaScale}) {
        my $scale = $properties->{karmaScale} || $self->karmaScale || 1;
        my $karma = $properties->{karma} || $self->karma;
        $properties->{karmaRanking} = $karma / $scale;
    }
    #Update Ticket
    $self->SUPER::update($properties, @_);

	#update the Ticket meta data
    if( defined $properties->{metadata} && ref $properties->{metadata} eq 'ARRAY' ) {
	foreach my $props (@{$properties->{metadata}}) {
	    $db->write(
		"REPLACE into Ticket_metaData (fieldId,assetId,value) values (?,?,?)",
		[$props->{fieldId},$self->getId,$props->{value}]
	    );
	}
    }

    my $props = {
        assetId         => $self->getId,
        parentId        => $self->getParent->getId,
        lineage         => $self->lineage,
        url             => $self->getUrl,
        ticketId        => $self->ticketId,
        creationDate    => $self->creationDate,
        createdBy       => $self->createdBy,
        synopsis        => $self->synopsis,
        title           => $self->title,
        isPrivate       => $self->isPrivate,
        keywords        => $self->keywords,
        assignedTo      => $self->assignedTo,
        assignedBy      => $self->assignedBy,
        dateAssigned    => $self->dateAssigned,
        ticketStatus    => $self->ticketStatus,
        solutionSummary => $self->solutionSummary,
        lastReplyDate   => $self->lastReplyDate,
        lastReplyBy     => $self->lastReplyBy,
        karmaRank       => $self->karmaRank
    };

    my $metaFields = $parent->getHelpDeskMetaFields({searchOnly=>1});
    if(scalar(@{$metaFields})) {
        foreach my $field (@{$metaFields}) {
            my $fieldId    = $field->{fieldId};
            my $columnName = "field_".$fieldId; 
            $props->{$columnName} = $self->getTicketMetaData($fieldId);
        }
    }
    #update the search index
    $db->setRow("Ticket_searchIndex","assetId",$props,$self->getId);
	
}


#-------------------------------------------------------------------

=head2 view ( )

method called by the container www_view method. 

=cut

sub view {
	my $self      = shift;
    my $session   = $self->session;
    my $parent    = $self->getParent;
    my $user      = $session->user;
    my $i18n      = $self->i18n;

    #Formats a lot of data for display including meta data fields
    my $var       = $self->getCommonDisplayVars;

    #Output standard controls    
    $var->{'controls'         } = $self->getToolbar;

    #Determine whether or not the ticket manager is asking for the ticket
    $var->{'callerIsTicketMgr'} = $session->form->get("caller") eq "ticketMgr";
    
    #Determine the calling view so we load into the proper dom
    if($var->{'callerIsTicketMgr'}) {
        my $view = $session->form->get("view");
        if($view eq "my") {
            $var->{'url_ticketView'} = $parent->getUrl('func=viewMyTickets');
            $var->{'datatable_id'  } = "myTicketList";
        }
        elsif($view eq "search") {
            $var->{'url_ticketView'} = $parent->getUrl('func=search');
            $var->{'datatable_id'  } = "search"
        }
        else {
            $var->{'url_ticketView'} = $parent->getUrl('func=viewAllTickets');
            $var->{'datatable_id'  } = "ticketList";
        }
    }

    #Set up some data to return to the ticket page for display purposes
    $var->{'username'         } = $user->username;
    $var->{'statusValues'     } = JSON->new->encode($parent->getStatus);

    #Create URLs for post backs
    $var->{'url_ticketMgr'    } = $parent->getUrl;
    $var->{'url_self'         } = $self->getUrl;
    $var->{'url_postFile'     } = $self->getUrl('func=uploadFile');
    $var->{'url_listFile'     } = $self->getUrl('func=fileList');
    $var->{'url_userSearch'   } = $self->getUrl('func=userSearch');
    $var->{'url_postSolution' } = $self->getUrl('func=postSolution');
    $var->{'url_postComment'  } = $self->getUrl('func=postComment');
    $var->{'url_getComment'   } = $self->getUrl('func=getComments');
    $var->{'url_setAssignment'} = $self->getUrl("func=setAssignment");
    $var->{'url_postKeywords' } = $self->getUrl("func=postKeywords");
    $var->{'url_getFormField' } = $self->getUrl("func=getFormField");
    $var->{'url_saveFormField'} = $self->getUrl("func=saveFormField");
    $var->{'url_getHistory'   } = $self->getUrl("func=getHistory");
    $var->{'url_transferKarma'} = $self->getUrl("func=transferKarma");

    #Format Data for Display
    $var->{'averageRating_src'} = $self->getAverageRatingImage($var->{'averageRating'});
    $var->{'averageRating'    } = sprintf("%.1f", $var->{'averageRating'});
    $var->{'solutionStyle'    } = "display:none;" unless ( isIn($self->ticketStatus,qw(resolved closed)) );
    #$var->{'isPrivate'        } = $self->isPrivate;

    #Icons
    $var->{'edit_icon_src'    } = $self->session->icon->getBaseURL()."edit.gif";
    $var->{'edit_icon'        } = $self->getImageIcon('edit',$i18n->get('change'));
    $var->{'unassign_icon'    } = $self->getImageIcon('delete',$i18n->get('unassign'));
    
    #Send permissions to the tempalte
    $var->{'canPost'                 } = $self->canPost;
    $var->{'canEdit'                 } = $self->canEdit;
    $var->{'canSubscribe'            } = $parent->canSubscribe;
    $var->{'canUpdate'               } = $self->canUpdate;
    $var->{'canChangeStatus'         } = $self->canChangeStatus;
    $var->{'canAssign'               } = $self->canAssign;
    $var->{'isVisitor'               } = $user->isVisitor;
    $var->{'isOwner'                 } = $user->userId eq $self->ownerUserId;
    $var->{'ticketResolved'          } = $self->ticketStatus eq "resolved";
    $var->{'ticketResolvedAndIsOwner'} = $var->{'ticketResolved'} && $var->{'isOwner'};
    $var->{'ticketStatus'            } = $self->ticketStatusEdit;

    #Process template for Related Files
    my $relatedFilesVars        = $self->getRelatedFilesVars($var->{'storageId'});
    $var->{'relatedFiles'     } = $self->www_fileList($relatedFilesVars);

    #Process comments
    $var->{'comments'         } = $self->www_getComments;

    #Set some more permission levels for the template
    $var->{'hasFiles'         } = $relatedFilesVars->{'hasFiles'};
    $var->{'hasFilesOrCanPost'} = $var->{'canPost'} || $var->{'hasFiles'};

    #Keywords
    my $keywords = WebGUI::Keyword->new($session)->getKeywordsForAsset({
        asset      => $self,
        asArrayRef =>1
    });
    my @keywordLoop = map { { 'keyword' => $_ } } @{$keywords};
    $var->{'hasKeywords'  } = scalar(@keywordLoop);
    $var->{'keywords_loop'} = \@keywordLoop;

    #Karma
    $var->{'useKarma'         } = $parent->karmaIsEnabled;
    $var->{'karma'            } = $self->karma || 0;
    if( $self->canEdit ) {
        $var->{'karmaScale'} = WebGUI::Form::text($session,{
			    name      => "karmaScale",
			    value     => $self->karmaScale,
			    maxlength => "11",
                            extras  => q{class="dyn_form_field" onchange="WebGUI.Ticket.saveKarmaScale(this)"}
			})
    } else {
        $var->{'karmaScale'       } = $self->karmaScale;
    }
    $var->{'karmaRank'        } = sprintf("%.2f",$self->karmaRank);
    $var->{'hasKarma'         } = ($user->isRegistered && $user->karma > 0);
    
    #History
    $var->{'ticket_history'   } = $self->www_getHistory;

    #Subscriptions - don't show the subscribe link on the ticket if user is already subscribed to the help desk
    #unless($parent->isSubscribed) {
    $var->{'showSubscribeLink'} = $parent->canSubscribe;
    $var->{'url_subscribe'    } = $self->getUrl("func=toggleSubscription");
    $var->{'subscribe_label'  } = $self->getSubscriptionMessage;
    #}
    

    #Add controls for people who can post
    if($var->{'canPost'}) {
        #Post Files
        $var->{ 'file_form_start'     } 
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=uploadFile'),
                extras  => q{id="fileUploadForm"}
            });
        
        #Post Comments
        $var->{'comments_form_start'  }
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=postComment;action=post'),
                extras  => q{id="commentsForm"}
            });
        $var->{'comments_form_comment'}
            = WebGUI::Form::textarea( $session, {
                name=>"comment",
                resizable=>0,
                width=>460
            });
        $var->{'comments_form_rating' }
            = WebGUI::Form::commentRating($session, {
                name           =>"rating",
                imagePath      =>$ratingUrl,
                imageExtension =>"png",
                defaultRating  => "0"
            });
        $var->{ 'form_end'   } = WebGUI::Form::formFooter( $session );
    }
    
    #Add controls for people who can update the ticket
    if($var->{'canUpdate'}) {
        $var->{'keywords_form_start'  }
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=postKeywords'),
                extras  => q{id="keywordsForm"}
            });
        $var->{'keywords_form'}
            = WebGUI::Form::text( $session, {
                name    => "keywords",
                value   => join(" ", map({ (m/\s/) ? '"' . $_ . '"' : $_ } @{$keywords})),
            });

        $var->{ 'form_end'   } = WebGUI::Form::formFooter( $session );

    }
    
    #Add controls for people who can assign the ticket to someone else
    if($var->{'canAssign'}) {
        $var->{ 'userSearch_form_start'} 
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=userSearch'),
                extras  => q{id="userSearchForm"}
            });
        $var->{ 'form_end'   } = WebGUI::Form::formFooter( $session );
    }

    #Add controls for people who can change status
    if($var->{'canChangeStatus'}) {
        $var->{'solution_form_start'  }
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=postComment'),
                extras  => q{id="postSolutionForm"}
            });
        $var->{ 'form_end'   } = WebGUI::Form::formFooter( $session );
    }

    #Process template and determine whether to return the parent style or not.
    my $output = $self->processTemplate($var,$parent->viewTicketTemplateId);
    if ($var->{'callerIsTicketMgr'}) {
        $session->response->content_type( 'application/json' );
        WebGUI::Macro::process( $session, \$output );
        $output = JSON->new->encode({
            ticketText => $output,
            ticketId => $self->ticketId,
        });
        $session->log->preventDebugOutput;
    } else {
        $session->response->content_type( 'text/html' );
       $output = $parent->processStyle($output),
    }
    
    return $output
}

#-------------------------------------------------------------------

=head2 www_copy ( )

Overrides the default copy functionality and does nothing.

=cut

sub www_copy {
    my $self = shift;
    return $self->session->privilege->insufficient unless $self->canEdit;
    return $self->getParent->processStyle("Tickets cannot be copied");
}

#----------------------------------------------------------------------------

=head2 www_fileList ( ) 

Returns the list of files to be displayed in the view template.

=cut

sub www_fileList {
    my $self      = shift;
    my $session   = $self->session;
    my $parent    = $self->getParent;

    return $self->session->privilege->insufficient  unless $self->canView;

    my $var       = shift || $self->getRelatedFilesVars($self->storageId,$parent->canPost);

    $session->response->content_type( 'text/html' );
    return $self->processTemplate(
        $var,
        $parent->viewTicketRelatedFilesTemplateId
    );
}

#----------------------------------------------------------------------------

=head2 www_getComments ( ) 

Gets the comments to display on the view ticket page.

=cut

sub www_getComments {
    my $self      = shift;
    my $session   = $self->session;
    my $dt        = $session->datetime;
    my $parent    = $self->getParent;
    my $var       = {};

    return $self->session->privilege->insufficient  unless $self->canView;

    #Get the comments
    $var->{'comments_loop'} = $self->comments;

    foreach my $comment (@{$var->{'comments_loop'}}) {
        my $rating = $comment->{rating} || "0";
        my ($date,$time) = split("~~~",$dt->epochToHuman($comment->{'date'},"%z~~~%Z"));
        my $user = WebGUI::User->new($session,$comment->{'userId'});
        $comment->{'userAlias'         } = $user->profileField('alias');
        $comment->{'userUrl'           } = $user->getProfileUrl;
        $comment->{'date_formatted'    } = $date;
        $comment->{'time_formatted'    } = $time;
        $comment->{'datetime_formatted'} = $date." ".$time;
        $comment->{'rating_image'      } = $session->url->extras('wobject/HelpDesk/rating/'.$rating.'.png');
                       # if Visitor(userid=1) can post comments then Admin can edit them
        $comment->{'canEdit'           } = $comment->{userId} eq '1' ? $session->user->userId eq '3' :
                            $comment->{userId} eq $session->user->userId;
        $comment->{'commentId'         } = $comment->{id};
    }
    
    $session->response->content_type( 'text/html' );
    $session->log->preventDebugOutput;
    return $self->processTemplate(
        $var,
        $parent->viewTicketCommentsTemplateId
    );
}

#----------------------------------------------------------------------------

=head2 www_getFormField ( ) 

Returns the form field for the id passed in

=cut

sub www_getFormField {
    my $self        = shift;
    my $session     = $self->session;
    my $fieldId     = $session->form->get("fieldId");
    my $parent      = $self->getParent;
    
    my $htmlElement = "";

    #Handle ticket status
    if($fieldId eq "ticketStatus") {
        #Only users who can change the status should be returned the form field
        return $session->privilege->insufficient  unless $self->canChangeStatus;
        my $value   = $self->ticketStatus;

        $htmlElement = $self->ticketStatusEdit;
    }
    #Handle karma scale
    elsif($fieldId eq "karmaScale") {
        #Only users who have edit privileges should be able to change the karma scale
        return $session->privilege->insufficient  unless $self->canEdit;
        $htmlElement = WebGUI::Form::text($session,{
            name      => "karmaScale",
            value     => $self->karmaScale,
            maxlength => "11",
            extras  => q{class="dyn_form_field"}
        })
    }
    elsif($fieldId =~ /comment_/ ) {
        return $session->privilege->insufficient  unless $self->canPost;
        my $commentText = '';
        my $commentRating = 0;
        my $comments  = $self->comments;    
        my $commentId = $fieldId;
        $commentId =~ s/comment_//;
        for my $item ( @$comments ) {
	    if( $item->{id} eq $commentId ) {
	        $commentText = $item->{comment};
	        $commentRating = $item->{rating};
                last;
	    }
        }
        $htmlElement = WebGUI::Form::textarea($session,{
            name      => "comment",
            value     => $commentText,
            rows      => "4",     # TODO change these to match ...
            cols      => "20",
            extras  => q{class="dyn_form_field"}
        });
        $htmlElement .= WebGUI::Form::commentRating($session,{
            name      => "rating",
            value     => $commentRating,
	    imagePath      =>$ratingUrl,
	    imageExtension =>"png",
            extras  => q{class="dyn_form_field"}
       });
    } else {
        #Only users who have update privileges should be able to change the metadata fields
        return $session->privilege->insufficient  unless $self->canUpdate;
        return "" unless $fieldId;

        my $field = $parent->getHelpDeskMetaField($fieldId);

        my $props = {
            name         => "field_".$fieldId,
            value        => $self->getTicketMetaData($fieldId),
            defaultValue => $field->{defaultValues},
            options	     => $field->{possibleValues},
            fieldType    => $field->{dataType},
            extras       => q{class="dyn_form_field"}
        };

        $htmlElement = WebGUI::Form::DynamicField->new($session,%{$props})->toHtml;
    }

    #Get the raw head tags for any javascript stuff that needs to run
    my $headtags = $session->style->generateAdditionalHeadTags;
    #Return the output
    my $output = qq{<form id="form_$fieldId">$headtags $htmlElement<input type="hidden" name="fieldId" value="$fieldId"></form>};
    $session->response->content_type( 'text/html' );
    $session->log->preventDebugOutput;
    return $output;
}

#----------------------------------------------------------------------------

=head2 www_getHistory ( ) 

Gets the history to display on the view ticket page.

=cut

sub www_getHistory {
    my $self      = shift;
    my $var       = {};
    my $session = $self->session;

    return $session->privilege->insufficient  unless $self->canView;

    #Get the comments
    $var->{'history_loop'} = $self->getHistory;
    
    foreach my $history (@{$var->{'history_loop'}}) {
        my $user = WebGUI::User->new($session,$history->{'history_userId'});
        $history->{'userUrl'           } = $user->getProfileUrl;
    }

    $session->response->content_type( 'text/html' );
    $session->log->preventDebugOutput;
    return $self->processTemplate(
        $var,
        $self->getParent->viewTicketHistoryTemplateId
    );
}

#----------------------------------------------------------------------------

=head2 www_postComment (  ) 

Posts a comment to the ticket

=cut

sub www_postComment {
    my $self      = shift;
    my $session   = $self->session;
    my $form      = $session->form;
    my $comment   = shift || $form->process("comment","textarea");
    my $user      = shift || $session->user;
    my $commentId = shift || $form->process("commentId") || 'new';
    return  $session->privilege->insufficient unless $user->isRegistered;
    my $i18n      = $self->i18n;
    my @errors    = ();
    my $solution;

    #Negate Macros on the comment
    #$comment = WebGUI::HTML::filter($comment, 'all');
    $comment = WebGUI::HTML::format($comment, 'text');
    WebGUI::Macro::negate(\$comment) if($comment);
    #$session->log->warn("close button clicked?".$form->get("closeTicket"));
    $session->response->content_type( 'application/json' );
   
    #Check for errors
    unless ($self->canPost) {
        push(@errors,'You do not have permission to post a comment to this ticket');
    }

    if($comment eq "") {
        push(@errors,'You have entered an empty comment');
    }

    return $self->processErrors(\@errors) if(scalar(@errors));

    #Get the rating
    my $rating   = $form->process('rating','commentRating',"0", { defaultRating  => "0" });

    my $status = $form->get("setFormStatus");

    if( $status eq 'resolved' and $solution eq '' ) {
        $solution = $comment;
    }

    #Post the comment to the comments
    $self->postComment($comment,{
        rating       => $rating,
        solution     => $solution,
        status       => $status,
        closeTicket  => ($form->get("close") eq "closed"),
        commentId    => $commentId,
    });

    my $avgRating    = $self->averageRating;

    #Return JSON to the page
    $session->response->content_type( 'text/JSON' );
    return JSON->new->encode({
        averageRating      => sprintf("%.1f", $avgRating),
        averageRatingImage => $self->getAverageRatingImage($avgRating),
        solutionSummary    => $self->solutionSummary,
        ticketStatus       => $self->ticketStatus,
        ticketStatusField  => $self->ticketStatusEdit,
        karmaLeft          => $user->karma,
    });
}

#----------------------------------------------------------------------------

=head2 www_postKeywords ( ) 

Posts the keywords and returns an array reference of them

=cut

sub www_postKeywords {
    my $self      = shift;
    my $session   = $self->session;

    my $keywords  = $session->form->process("keywords");
    my @errors    = ();

    $session->response->content_type( 'application/json' );
   
    unless ($self->canUpdate) {
        push(@errors,'You do not have permission to post keywords to this ticket');
    }

    return $self->processErrors(\@errors) if(scalar(@errors));

    $self->update({ keywords => $keywords });
    
    my $keywords = WebGUI::Keyword->new($session)->getKeywordsForAsset({
        asset      => $self,
        asArrayRef =>1
    });

    $session->response->content_type( 'text/JSON' );
    return JSON->new->encode( { keywords=>$keywords } );
}

#----------------------------------------------------------------------------

=head2 www_saveFormField ( ) 

Saves the form field and returns the value.

=cut

sub www_saveFormField {
    my $self      = shift;
    my $session   = $self->session;
    my $form = $session->form;
    my $parent    = $self->getParent;
    my $fieldId   = $session->form->get("fieldId");
    my $username  = $session->user->username;

    my @errors    = ();

    $session->response->content_type( 'application/json' );

    #Handle ticket status posts
    if($fieldId eq "ticketStatus") {
        #Get the value of the status
        my $value     = $form->get("ticketStatus") || $form->get("value");
        #Check ticket status change permissions
        push(@errors,'ERROR: You do not have permission to change the status of this ticket') unless($self->canChangeStatus);
        return $self->processErrors(\@errors) if(scalar(@errors));
        #Update the status
        $self->setStatus($value);
        #Get the user's current karma as this may have changed
        my $karma = $session->user->karma;
        #Return data
            # TODO this should return the whole html element incase there are changes...
        return "{ value:'$value', username:'$username', karmaLeft : '$karma' }";
    }
    #Handle karma scale posts
    elsif($fieldId eq "karmaScale") {
        #Get the value of the karma scale
        my $value     = $session->form->get("karmaScale") || $form->get("value");
        #Handle karma errors
        push(@errors,'ERROR: You do not have permission to change the difficulty of this ticket') unless($self->canEdit);
        push(@errors,'ERROR: Difficulty cannot be zero or empty') unless($value);
        return $self->processErrors(\@errors) if(scalar(@errors));
        #Set karma values
        $self->setKarmaScale($value);
        my $karmaScale = $self->karmaScale;
        my $karmaRank  = sprintf("%.2f",$self->karmaRank);
        return "{ value: '$karmaScale', username:'$username', karmaRank:'$karmaRank'}";
    }
    elsif($fieldId =~ /comment_/ ) {
        my $commentId = $fieldId;
        $commentId =~ s/comment_//;
        my $comment = $session->form->get('comment');
        my $rating = $session->form->get('rating');
        my $ratingImage = $self->session->url->extras($ratingUrl.$rating.".png");
        my $ratingId = 'comment_rating_' . $commentId;
        $self->postComment($session->form->get('comment'),{
            rating       => $rating,
            commentId    => $commentId,
        });
        $comment =~ s/\n/ /g;
        return "{ value: '$comment', rating:'$rating'," .
               " ratingId: '$ratingId', ratingImage:'$ratingImage'}";
    }

    #Handle meta field posts
    push(@errors,'ERROR: You do not have permission to edit the values of this ticket') unless ($self->canUpdate);
    push(@errors,'ERROR: No fieldId passed in.') unless ($fieldId);
    
    #Get the meta field properties
    my $field = $self->getParent->getHelpDeskMetaField($fieldId);
    #Get the value of the field
    my $value     = $session->form->get("field_".$fieldId,$field->{dataType});
    if($field->{required} && $value eq "") {
        push(@errors,'ERROR: '.$field->{label}.' cannot be empty.  Please enter a value');
    }

    $session->response->content_type( 'text/JSON' );
    return $self->processErrors(\@errors) if(scalar(@errors));

    #Update the database
    $self->setTicketMetaData($fieldId,$value);
    
    #Get the field value
    my $props = {
        name         => "field_".$fieldId,
		value        => $value,
		defaultValue => $field->{defaultValues},
		options	     => $field->{possibleValues},
        fieldType    => $field->{dataType},
    };

    $value = WebGUI::Form::DynamicField->new($session,%{$props})->getValueAsHtml;
    $session->log->preventDebugOutput;

    return "{ value:'$value', username:'$username' }";
}

#----------------------------------------------------------------------------

=head2 www_setAssignment ( ) 

Properly sets who the ticket is assigned to.

=cut

sub www_setAssignment {
    my $self        = shift;
    my $session     = $self->session;
    my $i18n        = $self->i18n;

    my $assignedTo  = $session->form->get("assignedTo");
    my $nowAssigned = $self->assignedTo;
    my @errors      = ();
    
    #Set the mime type
    $session->response->content_type( 'application/json' );
    
    #Process Errors
    unless ($self->canAssign) {
        push(@errors,'You do not have permission to assign this ticket');
    }
    unless ($assignedTo) {
        push(@errors,'You have not chosen someone to assign this ticket to.');
    }
    if( $assignedTo eq 'Assign2Me' ) {
        $assignedTo = $session->user->getId;
    }

    return $self->processErrors(\@errors) if(scalar(@errors));
    
    my $userId        = $session->user->getId;
    my $dateAssigned  = $session->datetime->time();
    my $username      = "unassigned";
    my $linkedUsername = $username;

    #If assignedTo is unassigned, unset it so we remove the assignement in the db
    if($assignedTo eq "unassigned" ) {
        $assignedTo = "";
    }
    #Otherwise, let's get the username of the person who this is assigned to
    else {
        my $user = WebGUI::User->new($session,$assignedTo);
        $username = $user->username;
        $linkedUsername = makeAnchorTag( $user->getProfileUrl, $username );
    }

    #Update the db
    $self->update({
        assigned     => 1,
        assignedTo   =>$assignedTo,
        assignedBy   =>$userId,
        dateAssigned =>$dateAssigned
    });

     #Log the change in assignment
    $self->logHistory("Assigned to ".$username);

    #Subscribe the user assigned
    if($assignedTo) {
        $self->subscribe($assignedTo);
        #Notify the user
        $self->sendMail({
            toUser  => $assignedTo,
            subject => $i18n->get("notification_assignment_subject"),
            message => sprintf($i18n->get("notification_assignment_message"),$self->getUrl,$self->getTitle),
        });
    }

    #Unsubscribe the user that was assigned
    if($nowAssigned) {
        $self->unsubscribe($nowAssigned);
        #Notify the user
        $self->sendMail({
            toUser  => $nowAssigned,
            subject => $i18n->get("notification_assignment_subject"),
            message => sprintf($i18n->get("notification_unassignment_message"),$self->getUrl,$self->getTitle),
        });
    }

    #Notify the user that the ticket has had a change in assignment
    my $userMsg = $assignedTo
                ? $i18n->get("notification_owner_assignment_message")
                : $i18n->get("notification_owner_unassignment_message")
                ;

    $self->sendMail({
        toUser  => $self->createdBy,
        subject => $i18n->get("notification_assignment_subject"),
        message => sprintf($userMsg,$self->getUrl,$self->getTitle,$username),
    });

    #Return the data
    $session->response->content_type( 'text/JSON' );
    my $assignedByUser = WebGUI::User->new($session,$userId);
    return JSON->new->encode({
        assignedTo   => $linkedUsername,
        dateAssigned => $session->datetime->epochToSet($dateAssigned),
        assignedBy   => makeAnchorTag( $assignedByUser->getProfileUrl, $assignedByUser->username ),
    });
}

#----------------------------------------------------------------------------

=head2 www_subscribe ( ) 

User friendly method that subscribes the user to the ticket (doesn't return JSON)

=cut

sub www_subscribe {
    my $self      = shift;

    return $self->session->privilege->insufficient  unless $self->getParent->canSubscribe;
    
    $self->www_toggleSubscription;
    return "";
}

#----------------------------------------------------------------------------

=head2 www_toggleSubscription ( ) 

Subscribes or unsubscribes the user from the ticket returning the opposite text

=cut

sub www_toggleSubscription {
    my $self      = shift;
    my $session   = $self->session;
    my $i18n      = $self->i18n;
    my $parent    = $self->getParent;

    my @errors = ();

    $session->response->content_type( 'application/json' );
   
    unless ($parent->canSubscribe) {
        push(@errors,'You do not have permission to subscribe to this Ticket');
    }

    if(scalar(@errors)) {    
        $session->response->content_type( 'text/JSON' );
        return JSON->new->encode({
            hasError =>"true",
            errors   =>\@errors
        });
    }

    my $returnStr = "";
    if($self->isSubscribedToTicket) {
        #unsubscribe the user
        $self->unsubscribe;
        #return the subscribe text (opposite)
        $returnStr = $i18n->get("subscribe_link");
    }
    else {
        #subscribe the user
        $self->subscribe;
        #return the unsubscribe test (opposite)
        $returnStr = $i18n->get("unsubscribe_link");
    }

    $session->response->content_type( 'text/JSON' );
    return "{ message : '$returnStr' }";
}

#----------------------------------------------------------------------------

=head2 www_transferKarma ( ) 

Properly transfers karma from a user to the ticket.

=cut

sub www_transferKarma {
    my $self     = shift;
    my $session  = $self->session;

    my $karma    = $session->form->get("karma") || 0;
    my @errors   = ();

    $session->response->content_type( 'application/json' );
   
    unless ($karma > 0) {
        push(@errors,'You have not entered any karma to be transferred');
    }
    unless ($self->hasKarma($karma)) {
        push(@errors,qq{You do not have enough karma to transfer $karma karma to this ticket});
    }
    if ($session->user->isVisitor) {
        push(@errors,'You must be logged in to transfer karma to a ticket');
    }
    
    return $self->processErrors(\@errors) if(scalar(@errors));
    
    $self->transferKarma($karma);
    
    $session->response->content_type( 'text/JSON' );
    #Get the current values from the object to return
    return JSON->new->encode({
        karma     => $self->karma,
        karmaRank => sprintf("%.2f",$self->karmaRank),
        karmaLeft => $session->user->karma,
    });    
}

#----------------------------------------------------------------------------

=head2 www_showConfirmation ( ) 

Shows the confirmation message after adding / editing a gallery album. 
Provides links to view the photo and add more photos.

=cut

sub www_showConfirmation {
    my $self        = shift;
    my $i18n        = $self->i18n;

    return $self->session->privilege->insufficient  unless $self->canView;

    return $self->getParent->processStyle(
        sprintf( $i18n->echo(q{Your ticket has been submitted and will be assigned to one of our technical staff shortly. <br /><div style="text-align:center;"><a href="%s">View All Tickets</a>&nbsp;|&nbsp;<a href="%s">View Ticket</a></div>.}),  
            $self->getParent->getUrl,
            $self->getUrl,
        )
    );
}

#----------------------------------------------------------------------------

=head2 www_unsubscribe ( ) 

User friendly method that unsubscribes the user from the ticket (doesn't return JSON)

=cut

sub www_unsubscribe {
    my $self      = shift;

    return $self->session->privilege->insufficient  unless $self->getParent->canSubscribe;
    
    $self->www_toggleSubscription;
    return "";
}

#----------------------------------------------------------------------------

=head2 www_uploadFile ( ) 

Properly uploads a file to it's storage location

=cut

sub www_uploadFile {
    my $self      = shift;
    my $session   = $self->session;
    my $i18n      = $self->i18n;
    
    unless ($self->getParent->canPost) {
    $session->response->content_type( 'text/JSON' );
        return "{
            hasError: true,
            errors: ['You do not have permission to post files to this ticket']
        }";
    }
    
    #Get the storage location
    my $store  = $self->getStorageLocation;    
    
    #Upload the file
    $store->addFileFromFormPost("attachment");

    #Notify subscribers
    $self->notifySubscribers({ content=>$i18n->get("notification_new_file_message") });
    
    #$session->response->content_type( 'text/JSON' );
    return " { x : 1 } ";
}

#----------------------------------------------------------------------------

=head2 www_userSearch ( ) 

Returns the list of users to be displayed by the user search.

=cut

sub www_userSearch {
    my $self      = shift;
    my $session   = $self->session;
    my $parent    = $self->getParent;
    
    my $var       = {};
    my $filter    = $session->form->process("search","text");
    
    if($filter) {
        $filter = "%".$filter."%";    
    }
    else {
        $filter = "%";    
    }

    #Wrote my own query to speed things up.  Should probably make this a class method inside the user API.
    my $query = q{
        select 
            users.userId,
            username
        from
            users
            left join userProfileData on users.userId = userProfileData.userId
        where 
            (
            lower(lastName) like ? 
            or lower(firstName) like ?
            or lower(users.username) like ?
            )
            and users.userId not in ('1','3')
        order by username asc
    };

    my $sth              = $session->db->read($query,[$filter,$filter,$filter]);
    my $numUsersReturned = $sth->rows;

    if($numUsersReturned == 0) {
        $var->{'noResults'} = "true";    
    }
    elsif($numUsersReturned > 50) {
        $var->{'tooManyResults'} = "true";    
    }
    else {
        my @userList = ();
        while (my $hashRef = $sth->hashRef) {    
            push (@userList, $hashRef);
        }
        $var->{'url_setAssignment'} = $self->getUrl("func=setAssignment");
        $var->{'users_loop'       } = \@userList;
    }

    $session->response->content_type( 'text/html' );
    $session->log->preventDebugOutput;
    return $self->processTemplate(
        $var,
        $parent->viewTicketUserListTemplateId
    );
}

#-------------------------------------------------------------------

=head2 www_view ( )

Web facing method which is the default view page.  This method does a 
302 redirect to the "showPage" file in the storage location.

=cut

sub www_view {
	my $self    = shift;
    my $session = $self->session;
	
    return $session->privilege->noAccess() unless $self->canView;

    return $self->view;
}

1;

