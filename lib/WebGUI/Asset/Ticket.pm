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

use strict;
use Tie::IxHash;
use JSON qw( decode_json encode_json );
use base 'WebGUI::Asset';
use WebGUI::Utility;

my $ratingUrl = "wobject/HelpDesk/rating/";

#-------------------------------------------------------------------

=head2 addRevision

   This method exists for demonstration purposes only.  The superclass
   handles revisions to NewAsset Assets.

=cut

sub addRevision {
	my $self = shift;
	my $newSelf = $self->SUPER::addRevision(@_);
	return $newSelf;
}

#-------------------------------------------------------------------
sub canAdd {
    my $class   = shift;
    my $session = shift;
    my $asset   = $session->asset;

    #Tickets can only be added to HelpDesk classes
    unless (ref $asset eq "WebGUI::Asset::Wobject::HelpDesk") {
        return 0;
    }
    return $session->user->isInGroup($asset->get('groupToPost'));
}

#-------------------------------------------------------------------
sub canEdit {
    my $self    = shift;
    my $session = $self->session;
    my $userId  = shift || $session->user->userId;
    my $form    = $self->session->form;
    my $user    = WebGUI::User->new( $session, $userId );
    my $func    = $form->get("func");
    my $assetId = $form->get("assetId");
    
    # Handle adding new tickets
    if ($func eq "add" || ( $func eq "editSave" && $assetId eq "new" )){
        return $self->canAdd($session);
    }

    # User who posted can edit their own post
    #if ( $self->isPoster( $userId ) ) {
    #    my $editTimeout = $self->getThread->getParent->get( 'editTimeout' );
    #    if ( $editTimeout > time - $self->get( "revisionDate" ) ) {
    #        return 1;
    #    }
    #}

    return $self->getParent->canEdit( $userId );
}

#-------------------------------------------------------------------
sub canView{
    my $self    = shift;
    my $userId  = $self->session->user->userId;
    
    my $ownerId   = $self->get("createdBy");
    my $assignedTo = $self->get("assignedTo");
    
    #Handle private cases
    if($self->get("isPrivate")) {
        return 1 if($userId eq $ownerId || $userId eq $assignedTo || $self->getParent->canEdit);
        return 0;
    }
    return $self->SUPER::canView(@_);
    
}

#-------------------------------------------------------------------
sub commit {
	my $self    = shift;
    my $session = $self->session;
    my $parent  = $self->getParent;
	$self->SUPER::commit;
    
    #$self->notifySubscribers unless ($self->shouldSkipNotification);
    
    #Award karma for new posts
	if ($self->get("creationDate") == $self->get("revisionDate")) {
        my $karmaPerPost = $parent->get("karmaPerPost");
		if ($parent->karmaIsEnabled && $karmaPerPost ){
			my $u = WebGUI::User->new($session, $self->get("createdBy"));
			$u->karma($karmaPerPost, $self->getId, "Help Desk post");
		}
	}
}

#-------------------------------------------------------------------

=head2 definition ( session, definition )

defines asset properties for New Asset instances.  You absolutely need 
this method in your new Assets. 

=head3 session

=head3 definition

A hash reference passed in from a subclass definition.

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	my $i18n = WebGUI::International->new($session, "Asset_Ticket");
	%properties = (
		storageId => {
            fieldType    =>"file",
            defaultValue =>undef,
        },
        ticketId => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        assigned => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        ticketStatus => {
            fieldType    =>"selectBox",
            defaultValue => "pending"
        },
        isPrivate => {
            fieldType    =>"yesNo",
            defaultValue => 0
        },
        assignedTo => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        assignedBy => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        dateAssigned => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        comments => {
			noFormPost	  => 1,
			fieldType     => "hidden",
			defaultValue  => [],
		},
        averageRating => {
            noFormPost	  => 1,
			fieldType     => "hidden",
			defaultValue  => 0,
		},
        lastReplyDate => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        lastReplyBy => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        resolvedBy => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        karma => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        karmaScale => {
            fieldType    =>"hidden",
            defaultValue =>undef,
        },
        karmaRank => {
            noFormPost   =>1,
            fieldType    =>"hidden",
            defaultValue =>undef
        },
        subscriptionGroup =>{
            noFormPost      =>1,
            fieldType       =>"hidden",
            defaultValue    =>undef,
        },
	);
    push(@{$definition}, {
        assetName  => $i18n->get('assetName'),
        tableName  => 'Ticket',
        className  => 'WebGUI::Asset::Ticket',
        properties => \%properties,
    });
	return $class->SUPER::definition($session, $definition);
}


#-------------------------------------------------------------------
sub duplicate {
	my $self = shift;
	my $newAsset = $self->SUPER::duplicate(@_);
	return $newAsset;
}

#-------------------------------------------------------------------
sub get {
	my $self = shift;
	my $param = shift;
	if ($param eq 'comments') {
		return decode_json($self->SUPER::get('comments')||'[]');
	}
	return $self->SUPER::get($param, @_);
}

#-------------------------------------------------------------------

=head2 getAverageRatingImage

   This method returns the average rating image based on the rating passed in

=cut

sub getAverageRatingImage {
	my $self   = shift;
    my $rating = shift || $self->get("averageRating");
    return  $self->session->url->extras($ratingUrl."0.png") unless ($rating);
    #Round to one digit integer
    my $imageId = int(sprintf("%1.0f", $rating));
    return $self->session->url->extras($ratingUrl.$imageId.".png");
}

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

=head2 getIcon (  )

Returns the icon passed in from the icon system.  This fuction is used
because $session->icon addtionally adds preset links to these icons.

=cut

sub getIcon {
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

#-------------------------------------------------------------------
sub getSubscriptionGroup {
	my $self  = shift;

    my $group = $self->get("subscriptionGroup");
    if ($group) {
		$group = WebGUI::Group->new($self->session,$group);
	}
    #Group Id was stored in the database but someone deleted the actual group
    unless($group) {
        $group = $self->getParent->createSubscriptionGroup($self,"ticket",$self->get("ticketId"));
    }
    return $group;
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

=head2 isSubscribed (  )

Returns a boolean indicating whether the user is subscribed to the ticket or help desk.

=cut

sub isSubscribed {
    my $self = shift;
    #Return true user is in the help desk subscription group
    return 1 if ($self->getParent->isSubscribed);
    #Return false if the subscription group is not set
    return 0 unless ($self->get("subscriptionGroup"));
	return $self->session->user->isInGroup($self->get("subscriptionGroup"));	
}

#----------------------------------------------------------------------------

=head2 logHistory ( ) 

log an event

=cut

sub logHistory {
    my $self        = shift;
    my $session     = $self->session;
    my $actionTaken = shift;    

    my $props   = {};
    $props->{'historyId'  } = "new";
    $props->{'actionTaken'} = $actionTaken;
    $props->{'dateStamp'  } = time();
    $props->{'userId'     } = $session->user->userId;
    $props->{'assetId'    } = $self->getId;

    $session->db->setRow("Ticket_history","historyId",$props);
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

    return encode_json( $errorHash );
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
    my $ticketId   = $self->get("ticketId");
    my $karmaScale = $form->get("karmaScale") || $self->get("karmaScale") || $parent->get("defaultKarmaScale");
    my $karma      = $self->get("karma");
    my $historyMsg = "Ticket edited";

    if ( $form->get('assetId') eq "new" ) {
        $ticketId   = $session->db->getNextId("ticketId");
        $historyMsg = "Ticket created";
    }

    $self->update( {
        url        => $session->url->urlize( join "/", $parent->get('url'), $ticketId ),
        ticketId   => $ticketId,
        karmaScale => $karmaScale,
        karma      => $karma,
    });

    #update the Ticket meta data
    foreach my $props (@metadata) {
        $db->write(
            "replace into Ticket_metaData (fieldId,assetId,value) values (?,?,?)",
            [$props->{fieldId},$assetId,$props->{value}]
        );
    }

    #Set the subscription group if it doesn't exist
    $self->getSubscriptionGroup();
    
    #Log the history
    $self->logHistory($historyMsg);

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
	my $self = shift;
	return $self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 purgeRevision ( )

This method is called when data is purged by the system.

=cut

sub purgeRevision {
	my $self = shift;
	return $self->SUPER::purgeRevision;
}

#----------------------------------------------------------------------------

=head2 setStatus ( ) 

Properly sets the current status of a ticket.

=cut

sub setStatus {
    my $self         = shift;
    my $session      = $self->session;
    my $parent       = $self->getParent;
    my $useKarma     = $parent->karmaIsEnabled;

    my $ticketStatus = shift;
    my $assetStatus  = $self->get("status");

    return 0 unless $ticketStatus;

    my $updates      = {};

    #Status is approved unless it's closed
    $updates->{'status'} = 'approved';

    #Handle closed tickets
    if($ticketStatus eq "closed") {
        if($useKarma) {
            my $amount     = $parent->get("karmaToClose");
            my $comment    = "Closed Ticket ".$self->get("ticketId");
            #Figure out who to give the karma to
            #If the ticket hasn't been resolved, then it is being manually closed.
            my $closedBy = $session->user;
            #Use resolved by if it's being automatically closed or manually resolved
            if($self->get("resolvedBy")) {
                $closedBy = WebGUI::User->new($session,$self->get("resolvedBy"));
            }
            $closedBy->karma($amount, $self->getId, $comment);
        }
        $updates->{'status'} = "archived";
    }
    elsif ($ticketStatus eq "resolved") {
        $updates->{'resolvedBy'} = $session->user->userId;
    }

    $updates->{'ticketStatus'} = $ticketStatus;

    $self->update($updates);

    #Log the change in status
    $self->logHistory($parent->getStatus($ticketStatus));

    return 1;
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
    my $karma      = $self->get("karma");

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
    my $karma        = $self->get("karma") + $amount;
    my $karmaScale   = $self->get("karmaScale");
    my $karmaRank    = $karma / $karmaScale;    

    #Update the ticket
    $self->update({
        karma      => $karma,
        karmaRank  => $karmaRank
    });
    
    #subtract the karma from the user
    $session->user->karma(-$amount,$self->getId,"Transferring karma to a ticket.");

    #Log the change in karma
    $self->logHistory("$amount karma transfered");

    return 1;
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
            $comments = eval{decode_json($comments)};
            if (WebGUI::Error->caught) {
                $comments = [];
            }
        }
        $properties->{comments} = encode_json($comments);
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
        $properties->{karmaScale} = $self->get("karmaScale") || $parent->get("defaultKarmaScale");
    }
    if ($properties->{karma} || $properties->{karmaScale}) {
        my $scale = $properties->{karmaScale} || $self->get("karmaScale") || 1;
        my $karma = $properties->{karma} || $self->get("karma");
        $properties->{karmaRanking} = $karma / $scale;
    }
    #Update Ticket
    $self->SUPER::update($properties, @_);

    my $props = {
        assetId         => $self->getId,
        parentId        => $self->getParent->getId,
        lineage         => $self->get("lineage"),
        url             => $self->getUrl,
        ticketId        => $self->get("ticketId"),
        creationDate    => $self->get("creationDate"),
        createdBy       => $self->get("createdBy"),
        synopsis        => $self->get("synopsis"),
        title           => $self->get("title"),
        isPrivate       => $self->get("isPrivate"),
        keywords        => $self->get("keywords"),
        assignedTo      => $self->get("assignedTo"),
        assignedBy      => $self->get("assignedBy"),
        dateAssigned    => $self->get("dateAssigned"),
        ticketStatus    => $self->get("ticketStatus"),
        solutionSummary => $self->get("solutionSummary"),
        lastReplyDate   => $self->get("lastReplyDate"),
        lastReplyBy     => $self->get("lastReplyBy"),
        karmaRank       => $self->get("karmaRank")
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
	my $self           = shift;
    my $session        = $self->session;
    my $parent         = $self->getParent;
    my $var            = $self->get;
    my $user           = $session->user;

    #Output standard controls    
    $var->{'controls'         } = $self->getToolbar;

    #Determine whether or not the ticket manager is asking for the ticket
    $var->{'callerIsTicketMgr'} = $session->form->get("caller") eq "ticketMgr";
    
    #Determine the calling view so we load into the proper dom
    if($var->{'callerIsTicketMgr'}) {
        my $view = $session->form->get("view");
        if($view eq "my") {
            $var->{'url_ticketView'} = $self->getParent->getUrl('func=viewMyTickets');
            $var->{'datatable_id'  } = "myTicketList";
        }
        elsif($view eq "search") {
            $var->{'url_ticketView'} = $self->getParent->getUrl('func=search');
            $var->{'datatable_id'  } = "search"
        }
        else {
            $var->{'url_ticketView'} = $self->getParent->getUrl('func=viewAllTickets');
            $var->{'datatable_id'  } = "ticketList";
        }
    }

    $var->{'url_ticketMgr'    } = $parent->getUrl;
	
    my $assignedTo = $var->{'assignedTo'};
    if ($assignedTo) {
        my $u = WebGUI::User->new($session,$assignedTo);
        $assignedTo = $u->username;
    }
    else {
        $assignedTo = "unassigned";
    }

    
    #Format Data for Display
    $var->{'ticketStatus'     } = $parent->getStatus($self->get("ticketStatus"));
    $var->{'assignedTo'       } = $assignedTo;
    $var->{'assignedBy'       } = WebGUI::User->new($session,$var->{'assignedBy'})->username;
    $var->{'createdBy'        } = WebGUI::User->new($session,$var->{'createdBy'})->username;
    $var->{'creationDate'     } = $session->datetime->epochToSet($var->{'creationDate'});
    $var->{'dateAssigned'     } = $session->datetime->epochToSet($var->{'dateAssigned'});
    $var->{'averageRating_src'} = $self->getAverageRatingImage($var->{'averageRating'});
    $var->{'averageRating'    } = sprintf("%.1f", $var->{'averageRating'});
    $var->{'solutionStyle'    } = "display:none;" unless ($self->get("ticketStatus") eq "closed");
    $var->{'isPrivate'        } = $self->get("isPrivate");

    #Icons
    $var->{'edit_icon'        } = $self->getIcon('edit','Change');
    $var->{'delete_icon'      } = $self->getIcon('delete');

    #Display metadata
    my $metafields   = $parent->getHelpDeskMetaFields({returnHashRef => 1});
    my $metadata     = $self->getTicketMetaData;
    my @metaDataLoop = ();
    foreach my $fieldId (keys %{$metadata}) {   
        my $props = {
            name         => "field_".$fieldId,
			value        => $metadata->{$fieldId},
			defaultValue => $metafields->{$fieldId}->{defaultValues},
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

    #Create URLs for post backs
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

    #Send permissions to the tempalte
    $var->{'canPost'          } = $self->getParent->canPost;
    $var->{'canEdit'          } = $self->getParent->canEdit;

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
    $var->{'karma'            } = $self->get("karma") || 0;
    $var->{'karmaScale'       } = $self->get("karmaScale");
    $var->{'karmaRank'        } = sprintf("%.2f",$self->get("karmaRank"));
    $var->{'hasKarma'         } = ($user->isRegistered && $user->karma > 0);
    
    #History
    $var->{'ticket_history'   } = $self->www_getHistory;

    #Subscriptions - don't show the subscribe link on the ticket if user is already subscribed to the help desk
    unless($parent->isSubscribed) {
        $var->{'showSubscribeLink'} = 1;
        $var->{'url_subscribe'    } = $self->getUrl("func=toggleSubscription");
        $var->{'subscribe_label'  } = ($self->isSubscribed) ? $i18n->get("unsubscribe_link") : $i18n->get("subscribe_link");
    }
    

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
    
    #Add controls for people who can edit
    if($var->{'canEdit'}) {
        $var->{ 'userSearch_form_start'} 
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=userSearch'),
                extras  => q{id="userSearchForm"}
            });
        $var->{'solution_form_start'  }
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=postComment;statusPost=1'),
                extras  => q{id="postSolutionForm"}
            });
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

    #Process template and determine whether to return the parent style or not.
    my $output = $self->processTemplate($var,$parent->get("viewTicketTemplateId"));
    unless ($var->{'callerIsTicketMgr'}) {
        $output = $parent->processStyle($output);
    }
    
    return $output
}


#----------------------------------------------------------------------------

=head2 www_edit ( )

Web facing method which is the default edit page

This page is only available to those who can edit this Ticket

=cut

sub www_edit {
    my $self       = shift;
    my $session    = $self->session;
    my $form       = $self->session->form;
    my $parent     = $self->getParent;

    return $self->session->privilege->insufficient  unless $self->canEdit;
    return $self->session->privilege->locked        unless $self->canEditIfLocked;

    # Prepare the template variables
    my $var         = {};
    $var->{isAdmin} = $parent->canEdit;

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
                action      => $parent->getUrl('func=editSave;assetId=new;class='.__PACKAGE__),
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
                value       => $self->get('ownerUserId'),
            })
            . WebGUI::Form::hidden( $session, {
                name        => 'ticketId',
                value       => $self->get("ticketId"),
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
            name        => "submit",
            value       => "Save",
        });

    $var->{ form_title  }
        = WebGUI::Form::Text( $session, {
            name        => "title",
            value       => ( $form->get("title") || $self->get("title") ),
        });
    

    $var->{ form_synopsis }
        = WebGUI::Form::HTMLArea( $session, {
            name        => "synopsis",
            value       => ( $form->get("synopsis") || $self->get("synopsis") ),
            richEditId  => $self->getParent->get("richEditIdPost"),
            height      => 300,
        });

    $var->{ form_attachment }
        = WebGUI::Form::file($session, {
            name            =>"storageId",
            value           =>$self->get("storageId"),
            maxAttachments  =>5,
            deleteFileUrl   =>$self->getUrl("func=deleteFile;filename=")
        });
    
    $var->{ form_isPrivate }
        = WebGUI::Form::yesNo( $session, {
            name        => "isPrivate",
            value       => ( $form->get("isPrivate") || $self->get("isPrivate") ),
        });
    
    $var->{ form_keywords }
        = WebGUI::Form::Text( $session, {
            name        => "keywords",
            value       => ( $form->get("keywords") || $self->get("keywords") ),
        });

    $var->{ useKarma        } = $parent->karmaIsEnabled;
    $var->{ form_karmaScale }
        = WebGUI::Form::Integer( $session, {
            name        => "karmaScale",
            value       => ( $form->get("karmaScale") || $self->get("karmaScale") || $parent->get("defaultKarmaScale") ),
        });
    

    #Build meta fields
    my $metadata       = $self->getTicketMetaData;
    my @metaFieldsLoop = ();
    foreach my $field (@{$parent->getHelpDeskMetaFields}) {
        my $fieldId = $field->{fieldId};
        my $props = {
            name         => "field_".$fieldId,
			value        => $metadata->{$fieldId},
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
    

    return $parent->processStyle(
        $self->processTemplate( $var, $parent->get("editTicketTemplateId") )
    );
}

#----------------------------------------------------------------------------

=head2 www_fileList ( ) 

Returns the list of files to be displayed in the view template.

=cut

sub www_fileList {
    my $self      = shift;
    my $session   = $self->session;
    my $parent    = $self->getParent;
    my $var       = shift || $self->getRelatedFilesVars($self->get('storageId'),$parent->canPost);

    return $self->processTemplate(
        $var,
        $parent->get("viewTicketRelatedFilesTemplateId")
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
    $var->{'comments_loop'} = $self->get('comments');

    foreach my $comment (@{$var->{'comments_loop'}}) {
        my ($date,$time) = split("~~~",$dt->epochToHuman($comment->{'date'},"%z~~~%Z"));
        $comment->{'date_formatted'    } = $date;
        $comment->{'time_formatted'    } = $time;
        $comment->{'datetime_formatted'} = $date." ".$time;
        $comment->{'rating_image'      } = $session->url->extras('wobject/HelpDesk/rating/'.$comment->{rating}.'.png');
        $comment->{'comment'           } = WebGUI::HTML::format($comment->{comment},'text');
    }
    
    return $self->processTemplate(
        $var,
        $parent->get("viewTicketCommentsTemplateId")
    );
}

#----------------------------------------------------------------------------

=head2 www_getFormField ( ) 

Returns the form field for the id passed in

=cut

sub www_getFormField {
    my $self      = shift;
    my $session   = $self->session;
    my $fieldId   = $session->form->get("fieldId");
    my $parent    = $self->getParent;

    return $session->privilege->insufficient  unless $self->canEdit;
    return "" unless $fieldId;

    if($fieldId eq "ticketStatus") {
        my $status = $parent->getStatus;
        delete $status->{pending};
        delete $status->{closed};

        return WebGUI::Form::selectBox($session,{
            name    =>"ticketStatus",
            options => $status,
            value   => $self->get("ticketStatus"),
            extras  => q{class="dyn_form_field"}
        });
    }
    elsif($fieldId eq "karmaScale") {
        return WebGUI::Form::text($session,{
            name      => "karmaScale",
            value     => $self->get("karmaScale"),
            maxlength => "11",
            extras  => q{class="dyn_form_field"}
        })
    }

    my $field = $self->getParent->getHelpDeskMetaField($fieldId);

    my $props = {
        name         => "field_".$fieldId,
		value        => $self->getTicketMetaData($fieldId),
		defaultValue => $field->{defaultValues},
		options	     => $field->{possibleValues},
        fieldType    => $field->{dataType},
        extras       => q{class="dyn_form_field"}
    };

	return WebGUI::Form::DynamicField->new($session,%{$props})->toHtml;
}

#----------------------------------------------------------------------------

=head2 www_getComments ( ) 

Gets the comments to display on the view ticket page.

=cut

sub www_getHistory {
    my $self      = shift;
    my $var       = {};

    return $self->session->privilege->insufficient  unless $self->canView;

    #Get the comments
    $var->{'history_loop'} = $self->getHistory;
    
    return $self->processTemplate(
        $var,
        $self->getParent->get("viewTicketHistoryTemplateId")
    );
}


#----------------------------------------------------------------------------

=head2 www_postComment ( ) 

Posts a comment to the ticket

=cut

sub www_postComment {
    my $self      = shift;
    my $session   = $self->session;
    my $form      = $session->form;
    my $user      = $session->user;
    my $parent    = $self->getParent;

    my $useKarma  = $parent->karmaIsEnabled;
    my $userId    = $user->userId;
    my $createdBy = $self->get("createdBy");
    my $now       = time();
    my @errors    = ();

    $session->http->setMimeType( 'application/json' );
   
    #Check for errors
    unless ($parent->canPost) {
        push(@errors,'You do not have permission to post a comment to this ticket');
    }

    if($form->get("comment") eq "") {
        push(@errors,'You have entered an empty comment');
    }

    return $self->processErrors(\@errors) if(scalar(@errors));

    #Get the comment
    my $comment  = $form->process('comment','textarea');
    WebGUI::Macro::negate(\$comment);

    #Get the rating
    my $rating   = $form->process('rating','commentRating',"0", { defaultRating  => "0" });
    
    #Post the comment to the comments
    my $comments  = $self->get('comments');    
    my $commentId = $session->id->generate;
	push @$comments, {
		id          => $commentId,
        alias		=> $user->profileField('alias'),
		userId		=> $user->userId,
		comment		=> $comment,
		rating		=> $rating,
		date		=> $now,
		ip			=> $self->session->var->get('lastIP'),
	};
	
    #Recalculate the rating
    my $count = 0;
    my $sum   = 0;
    map { $sum += $_->{rating}; $count++ if($_->{rating} > 0); } @{$comments};    
    #Avoid divide by zero errors
    $count = 1 unless ($count);
    my $avgRating = $sum/$count;

    #Update the Ticket.
	$self->update({
        comments      => $comments,
        averageRating => $avgRating,
        lastReplyDate => $now,
        lastReplyBy   => $user->userId,
    });
    
    #Award karma
    if($useKarma) {
        my $amount         = $parent->get("karmaPerPost");
        my $comment        = "Left comment for Ticket ".$self->get("ticketId");
        $user->karma($amount, $self->getId, $comment);
    }

    #Change the status to pending if the ticket is feedback or resolved
    my $ticketStatus = $self->get("ticketStatus");
    #Only reopen tickets if the poster was not updating the status
    unless($form->get("statusPost")) {
        if($ticketStatus eq "resolved" || $ticketStatus eq "feedback") {
            $self->setStatus("pending");
        }
    }

	#$self->notifySubscribers(
	#	$self->session->user->profileField('alias') .' said:<br /> '.WebGUI::HTML::format($comment,'text'),
	#	$self->getTitle . ' Comment',
	#	$user->profileField('email')
	#	);

    return encode_json({
        averageRating      => sprintf("%.1f", $avgRating),
        averageRatingImage => $self->getAverageRatingImage($avgRating),
        ticketStatus       => $parent->getStatus($self->get("ticketStatus")),
        commentId          => $commentId,
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

    $session->http->setMimeType( 'application/json' );
   
    unless ($self->getParent->canEdit) {
        push(@errors,'You do not have permission to post keywords to this ticket');
    }

    return $self->processErrors(\@errors) if(scalar(@errors));

    $self->update({ keywords => $keywords });
    
    my $keywords = WebGUI::Keyword->new($session)->getKeywordsForAsset({
        asset      => $self,
        asArrayRef =>1
    });

    return encode_json( { keywords=>$keywords } );
}

#----------------------------------------------------------------------------

=head2 www_postSolution ( ) 

Posts the solution summary and returns the data

=cut

sub www_postSolution {
    my $self      = shift;
    my $session   = $self->session;

    my $solution  = $session->form->process("solution","textarea");
    my @errors    = ();

    $session->http->setMimeType( 'application/json' );
   
    unless ($self->getParent->canEdit) {
        push(@errors,'You do not have permission to post a solution to this ticket');
    }

    return $self->processErrors(\@errors) if(scalar(@errors));

    my $hash = { solutionSummary  => $solution };
    $self->update($hash);
    
    return encode_json( $hash );
}

#----------------------------------------------------------------------------

=head2 www_saveFormField ( ) 

Saves the form field and returns the value.

=cut

sub www_saveFormField {
    my $self      = shift;
    my $session   = $self->session;
    my $parent    = $self->getParent;
    my $fieldId   = $session->form->get("fieldId");
    my $value     = $session->form->get("value");
    my $username  = $session->user->username;

    my @errors    = ();

    $session->http->setMimeType( 'application/json' );
   
    unless ($self->canEdit) {
        push(@errors,'ERROR: You do not have permission to edit the values of this ticket');
    }
    unless ($fieldId) {
        push(@errors,'ERROR: No fieldId passed in.');
    }

    #Handle ticket status posts
    if($fieldId eq "ticketStatus") {
        $self->setStatus($value);
        $value    = $parent->getStatus($value);
        my $karma = $session->user->karma;
        return "{ value:'$value', username:'$username', karmaLeft : '$karma' }";
    }
    #Handle karma scale posts
    elsif($fieldId eq "karmaScale") {
        #Handle karma errors
        return $self->processErrors(['Why would you try to set the difficulty to zero?  Are you dumb?']) unless($value);
        #Set karma values
        $self->setKarmaScale($value);
        my $karmaScale = $self->get("karmaScale");
        my $karmaRank  = sprintf("%.2f",$self->get("karmaRank"));
        return "{ value: '$karmaScale', username:'$username', karmaRank:'$karmaRank'}";
    }
    
    #Handle meta field posts
    my $field = $self->getParent->getHelpDeskMetaField($fieldId);
    if($field->{required} && $value eq "") {
        push(@errors,'ERROR: '.$field->{label}.' cannot be empty.  Please enter a value');
    }

    return $self->processErrors(\@errors) if(scalar(@errors));

    #Update the database
    $session->db->write(
        "update Ticket_metaData set value=? where fieldId=? and assetId=?",
        [$value,$fieldId,$self->getId]
    );
    
    #Get the field value
    my $props = {
        name         => "field_".$fieldId,
		value        => $value,
		defaultValue => $field->{defaultValues},
		options	     => $field->{possibleValues},
        fieldType    => $field->{dataType},
    };

    $value = WebGUI::Form::DynamicField->new($session,%{$props})->getValueAsHtml;

    return "{ value:'$value', username:'$username' }";
}

#----------------------------------------------------------------------------

=head2 www_setAssignment ( ) 

Properly sets who the ticket is assigned to.

=cut

sub www_setAssignment {
    my $self       = shift;
    my $session    = $self->session;

    my $assignedTo = $session->form->get("assignedTo");
    my @errors     = ();
    
    #Set the mime type
    $session->http->setMimeType( 'application/json' );
    
    #Process Errors
    unless ($self->getParent->canEdit) {
        push(@errors,'You do not have permission to assign this ticket');
    }
    unless ($assignedTo) {
        push(@errors,'You have not chosen someone to assign this ticket to.');
    }

    return $self->processErrors(\@errors) if(scalar(@errors));
    
    my $userId        = $session->user->userId;
    my $dateAssigned  = $session->datetime->time();
    my $username      = "unassigned";

    #If assignedTo is unassigned, unset it so we remove the assignement in the db
    if($assignedTo eq "unassigned" ) {
        $assignedTo = "";
    }
    #Otherwise, let's get the username of the person who this is assigned to
    else {
        $username = WebGUI::User->new($session,$assignedTo)->username;
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

    #Return the data

    return encode_json({
        assignedTo   => $username,
        dateAssigned => $session->datetime->epochToSet($dateAssigned),
        assignedBy   => WebGUI::User->new($session,$userId)->username,
    });
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

    #Create the subscription group if it doesn't yet exist
    my $group  = $self->getSubscriptionGroup();    
    my @errors = ();

    $session->http->setMimeType( 'application/json' );
   
    unless ($parent->canSubscribe) {
        push(@errors,'You do not have permission to subscribe to this Help Desk');
    }

    if($parent->isSubscribed) {
        push(@errors,'You are already subscribed to the Help Desk.  Please unsubscribe from the Help Desk before continuing');    
    }

    if(scalar(@errors)) {    
        return encode_json({
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

    $session->http->setMimeType( 'application/json' );
   
    unless ($karma > 0) {
        push(@errors,'You have not entered any karma to be transfered');
    }
    unless ($self->hasKarma($karma)) {
        push(@errors,qq{You do not have enough karma to transfer $karma karma to this ticket});
    }
    if ($session->user->isVisitor) {
        push(@errors,'You must be logged in to transfer karma to a ticket');
    }
    
    return $self->processErrors(\@errors) if(scalar(@errors));
    
    $self->transferKarma($karma);
    
    #Get the current values from the object to return
    return encode_json({
        karma     => $self->get("karma"),
        karmaRank => sprintf("%.2f",$self->get("karmaRank")),
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

=head2 www_uploadFile ( ) 

Properly uploads a file to it's storage location

=cut

sub www_uploadFile {
    my $self      = shift;
    my $session   = $self->session;
    
    unless ($self->getParent->canPost) {
        return "{
            hasError: true,
            errors: ['You do not have permission to post files to this ticket']
        }";
    }
    
    my $storageId = $self->get("storageId");
    my $store     = undef;    
    if ($storageId) {
        $store = WebGUI::Storage->get($session,$storageId);
    }
    else {
        #No storageId - create one and update the asset
        $store = WebGUI::Storage->create($session);
        $self->update({ storageId=>$store->getId });
    }
    
    #Upload the file
    $store->addFileFromFormPost("attachment");
    return "{}";
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
            IF(((select count(*) from userProfileData where userId=users.userId and firstName is not null and firstName <> "") + (select count(*) from userProfileData where userId=users.userId and lastName is not null and lastName <> "")) = 2,concat(lastName,", ",firstName),username) as username
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

    return $self->processTemplate(
        $var,
        $parent->get("viewTicketUserListTemplateId")
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

