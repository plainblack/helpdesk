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

use strict;
use Tie::IxHash;
use WebGUI::International;
use WebGUI::Utility;
use JSON qw( decode_json encode_json );
use base 'WebGUI::Asset::Wobject';

#----------------------------------------------------------------------------

=head2 addChild ( properties [, ... ] )

Add a Ticket to this HelpDesk. See C<WebGUI::AssetLineage> for more info.

Override to ensure only appropriate classes get added to the HelpDesk.

=cut

sub addChild {
    my $self        = shift;
    my $properties  = shift;
    my $fileClass   = 'WebGUI::Asset::Ticket';
    
    # Make sure we only add appropriate child classes
    unless($properties->{className} eq $fileClass) {
        $self->session->errorHandler->security(
            "add a ".$properties->{className}." to a ".$self->get("className")
        );
        return undef;
    }

    return $self->SUPER::addChild( $properties, @_ );
}

#-------------------------------------------------------------------

=head2 canAdd ( session )

Determine if the user has permission to post a ticket to the help desk

=cut

sub canPost {
    my $self    = shift;
    my $session = $self->session;
    
    return ($self->canEdit || $session->user->isInGroup($self->getValue('groupToPost')));
}

#-------------------------------------------------------------------
sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session, "Asset_HelpDesk");

	my %properties;
	tie %properties, 'Tie::IxHash';
	%properties = (
		viewTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'HELPDESK00000000000001',
			tab            => "display",
			namespace      => "HelpDesk/view", 
			hoverHelp      => $i18n->echo('Choose the template to use for the main view which is the tab wrapper of the other views'),
			label          => $i18n->echo('Main View Template'),
		},
        viewMyTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'HELPDESK00000000000002',
			tab            => "display",
			namespace      => "HelpDesk/myView", 
			hoverHelp      => $i18n->echo('Choose the template to use for the my view which is the global contents of all tickets assigned to the current user'),
			label          => $i18n->echo('My View Template'),
		},
        viewAllTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'HELPDESK00000000000003',
			tab            => "display",
			namespace      => "HelpDesk/viewAll", 
			hoverHelp      => $i18n->echo('Choose the template to use for the all view which displays all of the tickets local to this asset'),
			label          => $i18n->echo('View All Template'),
		},
        searchTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'HELPDESK00000000000004',
			tab            => "display",
			namespace      => "HelpDesk/search", 
			hoverHelp      => $i18n->echo('Choose the template to use for the search tab which allows users to search for and find tickets'),
			label          => $i18n->echo('Search Template'),
		},
        manageMetaTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'HELPDESK00000000000005',
			tab            => "display",
			namespace      => "HelpDesk/manageMeta", 
			hoverHelp      => $i18n->echo('Choose the template to use for managing help desk meta data'),
			label          => $i18n->echo('Manage Meta Data Template'),
		},
        editMetaFieldTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'HELPDESK00000000000006',
			tab            => "display",
			namespace      => "HelpDesk/editMetaField", 
			hoverHelp      => $i18n->echo('Choose the template to use for editing help desk meta fields'),
			label          => $i18n->echo('Edit Meta Field Template'),
		},
        editTicketTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'TICKET0000000000000001',
			tab            => "display",
			namespace      => "Ticket/edit",
			hoverHelp      => $i18n->echo('Choose the template to use for editing a ticket'),
			label          => $i18n->echo('Edit Ticket Template'),
		},
        viewTicketTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'TICKET0000000000000002',
			tab            => "display",
			namespace      => "Ticket/view", 
			hoverHelp      => $i18n->echo('Choose the template to use for the main view of a ticket'),
			label          => $i18n->echo('View Ticket Template'),
		},
        viewTicketRelatedFilesTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'TICKET0000000000000003',
			tab            => "display",
			namespace      => "Ticket/relatedFiles",
			hoverHelp      => $i18n->echo('Choose the template to use for displaying related files when viewing a ticket'),
			label          => $i18n->echo('Related Files for View Ticket Template'),
		},
        viewTicketUserListTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'TICKET0000000000000004',
			tab            => "display",
			namespace      => "Ticket/userList",
			hoverHelp      => $i18n->echo('Choose the template to use for displaying the list of users when assigning a ticket to a user'),
			label          => $i18n->echo('User List for View Ticket Template'),
		},
        viewTicketCommentsTemplateId =>{
            fieldType      => "template",  
			defaultValue   => 'TICKET0000000000000005',
			tab            => "display",
			namespace      => "Ticket/comments",
			hoverHelp      => $i18n->echo('Choose the template to use for displaying the comments when viewing a ticket'),
			label          => $i18n->echo('Comments for View Ticket Template'),
		},
        groupToPost => {
            tab            => "security",
            fieldType      => "group",
            defaultValue   => 2, # Registered Users
            label          => $i18n->echo("Who can post?"),
            hoverHelp      => $i18n->echo("Choose the group of users that can post bugs to the list"),
        },
        richEditIdPost => {
            tab             => "display",
            fieldType       => "selectRichEditor",
            defaultValue    => "PBrichedit000000000002", # Forum Rich Editor
            label           => $i18n->echo("Post Rich Editor"),
            hoverHelp       => $i18n->get("Choose the rich editor to use for posting"),
        },
   
	);
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		autoGenerateForms=>1,
		tableName=>'HelpDesk',
		className=>'WebGUI::Asset::Wobject::HelpDesk',
		properties=>\%properties
	});
    return $class->SUPER::definition($session, $definition);
}


#-------------------------------------------------------------------

=head2 duplicate ( )

duplicates a New Wobject.  This method is unnecessary, but if you have 
auxiliary, ancillary, or "collateral" data or files related to your 
wobject instances, you will need to duplicate them here.

=cut

sub duplicate {
	my $self = shift;
	my $newAsset = $self->SUPER::duplicate(@_);
	return $newAsset;
}

#-------------------------------------------------------------------
sub getContentLastModified {
    return time;
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
        %hash = (
            'new'          => 'New',
            'acknowledged' => 'Acknowledged',
            'feedback'     => 'Feedback Requested',
            'confirmed'    => 'Confirmed',
            'resolved'     => 'Resolved',
            'closed'       => 'Closed'
        );
        $self->{_status} = \%hash;
    }

    if($key) {
        return $self->{_status}->{$key};
    }
    
    return $self->{_status};
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

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $template = WebGUI::Asset::Template->new($self->session, $self->get("viewTemplateId"));

	$template->prepare;
	$self->{_viewTemplate} = $template;
}


#-------------------------------------------------------------------

=head2 purge ( )

removes collateral data associated with a NewWobject when the system
purges it's data.  This method is unnecessary, but if you have 
auxiliary, ancillary, or "collateral" data or files related to your 
wobject instances, you will need to purge them here.

=cut

sub purge {
	my $self = shift;
	#purge your wobject-specific data here.  This does not include fields 
	# you create for your NewWobject asset/wobject table.
	return $self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 view ( )

method called by the www_view method.  Returns a processed template
to be displayed within the page style.  

=cut

sub view {
	my $self = shift;
	my $session = $self->session;	

	#This automatically creates template variables for all of your wobject's properties.
	my $var = $self->get;
	
    $var->{'canPost'       } = $self->canPost;
    $var->{'canEdit'       } = $self->canEdit;
    $var->{'canEditAndPost'} = $var->{'canPost'} && $var->{'canEdit'};

    $var->{'url_viewAll'  } = $self->getUrl("func=viewAllTickets");
    $var->{'url_viewMy'   } = $self->getUrl("func=viewMyTickets");
    $var->{'url_search'   } = $self->getUrl("func=search");
    if($var->{'canPost'}) {
	    $var->{'url_addTicket'} = $self->getUrl("func=add;class=WebGUI::Asset::Ticket");
    }
    if($var->{'canEdit'}) {
       $var->{'url_manageMetaData'} = $self->getUrl("func=manageHelpDeskMetaFields");
    }
	
	return $self->processTemplate($var, undef, $self->{_viewTemplate});
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
        richEditId  => $self->get("richEditIdPost"),
        height      => 300,
    });

    $var->{'form_submit'       } = WebGUI::Form::submit($session, {
        name        => "submit",
        value       => $i18n->echo("Save"),
    });
    
    $var->{'form_end'          } = WebGUI::Form::formFooter( $session );

    return $self->processStyle(
        $self->processTemplate( $var, $self->get("editMetaFieldTemplateId") )
    );
}

#-------------------------------------------------------------------

=head2 www_editEventMetaFieldSave ( )

Processes the results from www_editHelpDeskMetaField ().

=cut

sub www_editHelpDeskMetaFieldSave {
	my $self    = shift;
    my $session = $self->session;
	my $form    = $session->form;
    my $i18n    = $self->i18n;

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
	
    my $newId = $self->setCollateral("HelpDesk_metaField", "fieldId",{
        fieldId        => $fieldId,
		label          => $form->process("label"),
		dataType       => $form->process("dataType",'fieldType'),
		searchable     => $form->process("searchable",'yesNo'),
		required       => $form->process("required",'yesNo'),
		possibleValues => $form->process("possibleValues",'textarea'),
		defaultValues  => $form->process("defaultValues",'textarea'),
        hoverHelp      => $form->process("hoverHelp",'HTMLArea'),
	},1,1);
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
    my $rowsPerPage = 25;
    my $ticketInfo  = {};    
    my $filter      = shift || $session->form->get("filter");

    return $session->privilege->insufficient unless $self->canView;


    my $orderByColumn       = $session->form->get( 'orderByColumn' ) 
                            || "creationDate"
                            ;
    my $orderByDirection    = lc $session->form->get( 'orderByDirection' ) eq "asc"
                            ? "ASC"
                            : "DESC"
                            ;

    #Only allow specific filter types
    unless(WebGUI::Utility::isIn($filter,"myTickets")) {
        $filter = "";
    }

    my $whereClause = q{Ticket.ticketStatus <> 'closed'};
    if($filter eq "myTickets") {
        my $userId = $session->user->userId;
        $whereClause .= qq{ and Ticket.assignedTo='$userId'};
    }

    my $rules;
    $rules->{'joinClass'         } = "WebGUI::Asset::Ticket";
    $rules->{'whereClause'       } = $whereClause;
    $rules->{'includeOnlyClasses'} = ['WebGUI::Asset::Ticket'];
    $rules->{'orderByClause'     } = $session->db->dbh->quote_identifier( $orderByColumn ) . ' ' . $orderByDirection;

    my $sql  = "";
    
    if($filter eq "myTickets") {
        $sql = $self->getRoot($session)->getLineageSql(['descendants'], $rules);
    }
    else {
        $sql = $self->getLineageSql(['children'], $rules);
    }

    my $recordOffset        = $session->form->get( 'recordOffset' ) || 1;
    my $rowsPerPage         = $session->form->get( 'rowsPerPage' ) || 10;
    my $currentPage         = int ( $recordOffset / $rowsPerPage ) + 1;
    
    my $p = WebGUI::Paginator->new( $session, '', $rowsPerPage, 'pn', $currentPage );
    $p->setDataByQuery($sql);

    $ticketInfo->{'recordsReturned'} = $rowsPerPage;
    $ticketInfo->{'totalRecords'   } = $p->getRowCount; 
    $ticketInfo->{'startIndex'     } = $recordOffset;
    $ticketInfo->{'sort'           } = $orderByColumn;
    $ticketInfo->{'dir'            } = $orderByDirection;
    $ticketInfo->{'tickets'        } = [];
    
    for my $record ( @{ $p->getPageData } ) {
        my $ticket = WebGUI::Asset->newByDynamicClass( $session, $record->{assetId} );
        
        my $assignedTo = $ticket->get("assignedTo");
        if ($assignedTo) {
           my $u = WebGUI::User->new($session,$assignedTo);
           $assignedTo = $u->username;
        }
        else {
           $assignedTo = "unassigned";
        }

        # Populate the required fields to fill in
        my %fields      = (
            ticketId      => $ticket->get("ticketId"),
            url           => $ticket->getUrl,
            title         => $ticket->get( "title" ),
            createdBy     => WebGUI::User->new($session,$ticket->get( "createdBy" ))->username,
            creationDate  => $session->datetime->epochToSet($ticket->get( "creationDate" )),
            assignedTo    => $assignedTo,
            ticketStatus  => $self->getStatus($ticket->get( "ticketStatus" )),
        );

        push @{ $ticketInfo->{ tickets } }, \%fields;
    }
    
    $session->http->setMimeType( 'application/json' );
    return encode_json( $ticketInfo );
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
    my $pageUrl    = $self->getUrl;

    my @fieldsLoop = ();
    foreach my $row (@{$metadataFields}) {
        $count++;
        my $hash    = {};
        my $fieldId = $row->{fieldId}; 
        
		$hash->{'icon_delete'   } = $icon->delete('func=deleteEventMetaField;fieldId='.$fieldId,$pageUrl,$deleteMsg);
		$hash->{'icon_edit'     } = $icon->edit('func=editHelpDeskMetaField;fieldId='.$fieldId, $pageUrl);
        $hash->{'icon_moveUp'   } = $icon->moveUp('func=moveHelpDeskMetaFieldUp;fieldId='.$fieldId, $pageUrl,($count == 1)?1:0);
		$hash->{'icon_moveDown' } = $icon->moveDown('func=moveHelpDeskMetaFieldDown;fieldId='.$fieldId, $pageUrl,($count == $numberOfFields)?1:0);
			
		$hash->{'metaFieldLabel'} = $row->{label};
	    push(@fieldsLoop,$hash);
    }
    
    $var->{'hasMetaFields'} = $numberOfFields;
    $var->{'fields_loop'  } = \@fieldsLoop;

	return $self->processStyle($self->processTemplate($var, $self->getValue("manageMetaTemplateId")));
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
    $var->{'url_pageData'} = $self->getUrl('func=getAllTickets');
    

    return $self->processTemplate($var, $self->getValue("viewAllTemplateId"));
}


#-------------------------------------------------------------------
sub www_viewMyTickets {
    my $self    = shift;
    my $session = $self->session;
    my $var     = {};

    return $session->privilege->insufficient unless $self->canView;

    
    $var->{'url_pageData'} = $self->getUrl('func=getAllTickets;filter=myTickets');
    

    return $self->processTemplate($var, $self->getValue("viewMyTemplateId"));
}

#-------------------------------------------------------------------
sub www_search {
    my $self    = shift;
    my $session = $self->session;
    my $var     = {};

    return $session->privilege->insufficient unless $self->canView;
    
    $var->{ 'form_start'     } 
        = WebGUI::Form::formHeader( $session, {
            action  => $self->getUrl('func=searchTickets'),
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
            name => "keyword",
        });

    tie my %status, "Tie::IxHash";
    %status = (""=>"Any",%{$self->getStatus});
    $var->{'form_status'    }
        = WebGUI::Form::SelectBox( $session, {
            name    => "ticketStatus",
            options => \%status
        });

    my $sql = qq{
        select
            distinct assignedTo,
            username
        from
            Ticket
            join users on userId=assignedTo
            join asset using(assetId)
        where
            assignedTo is not NULL
            and lineage like ?
        order by username
    };
    
    tie my %options, "Tie::IxHash";
    %options = $session->db->buildHash($sql,[$self->get("lineage")."%"]);
    %options = (""=>"Any","unassigned"=>"unassigned",%options);

    $var->{'form_assignedTo'}
        = WebGUI::Form::SelectBox( $session, {
            name    => "assignedTo",
            options => \%options
        });

    $sql = qq{
        select
            distinct assignedBy,
            username
        from
            Ticket
            join users on userId=assignedBy
            join asset using(assetId)
        where
            assignedBy is not NULL
            and lineage like ?
        order by username
    };
    %options = $session->db->buildHash($sql,[$self->get("lineage")."%"]);
    %options = (""=>"Any",%options);

    $var->{'form_assignedBy'}
        = WebGUI::Form::SelectBox( $session, {
            name    => "assignedBy",
            options => \%options
        });

    $var->{'form_ticketId'}
        = WebGUI::Form::Text( $session, {
            name => "ticketId"
        });

    $var->{'form_dateStart'}
        = WebGUI::Form::Date( $session, {
            name   => "dateStart",
            noDate => 1
        });

    $var->{'form_dateEnd'}
        = WebGUI::Form::Date( $session, {
            name   => "dateEnd",
            noDate => 1
        });


    #Build meta fields
    my @metaFieldsLoop = ();
    foreach my $field (@{$self->getHelpDeskMetaFields({searchOnly=>1})}) {
        my $fieldId = $field->{fieldId};
        my $props = {
            name         => "field_".$fieldId,
			options	     => qq{|Any\n}.$field->{possibleValues},
            fieldType    => $field->{dataType},
            defaultValue => ""
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

    $var->{'url_pageData'  } = $self->getUrl('func=searchTickets');

    return $self->processTemplate($var, $self->getValue("searchTemplateId"));
}

#-------------------------------------------------------------------
sub www_searchTickets {
    my $self        = shift;
    my $session     = $self->session;
    my $rowsPerPage = 25;
    my $ticketInfo  = {};    
    my $filter      = shift || $session->form->get("filter");

    return $session->privilege->insufficient unless $self->canView;


    my $orderByColumn       = $session->form->get( 'orderByColumn' ) 
                            || "creationDate"
                            ;
    my $orderByDirection    = lc $session->form->get( 'orderByDirection' ) eq "asc"
                            ? "ASC"
                            : "DESC"
                            ;

    
    my $whereClause = q{Ticket.ticketStatus <> 'closed'};
    if($filter eq "myTickets") {
        my $userId = $session->user->userId;
        $whereClause .= qq{ and Ticket.assignedTo='$userId'};
    }

    my $rules;
    $rules->{'joinClass'         } = "WebGUI::Asset::Ticket";
    $rules->{'whereClause'       } = $whereClause;
    $rules->{'includeOnlyClasses'} = ['WebGUI::Asset::Ticket'];
    $rules->{'orderByClause'     } = $session->db->dbh->quote_identifier( $orderByColumn ) . ' ' . $orderByDirection;

    my $sql  = "";
    
    $sql = $self->getLineageSql(['children'], $rules);
   
    my $recordOffset        = $session->form->get( 'recordOffset' ) || 1;
    my $rowsPerPage         = $session->form->get( 'rowsPerPage' ) || 10;
    my $currentPage         = int ( $recordOffset / $rowsPerPage ) + 1;
    
    my $p = WebGUI::Paginator->new( $session, '', $rowsPerPage, 'pn', $currentPage );
    $p->setDataByQuery($sql);

    $ticketInfo->{'recordsReturned'} = $rowsPerPage;
    $ticketInfo->{'totalRecords'   } = $p->getRowCount; 
    $ticketInfo->{'startIndex'     } = $recordOffset;
    $ticketInfo->{'sort'           } = $orderByColumn;
    $ticketInfo->{'dir'            } = $orderByDirection;
    $ticketInfo->{'tickets'        } = [];
    
    for my $record ( @{ $p->getPageData } ) {
        my $ticket = WebGUI::Asset->newByDynamicClass( $session, $record->{assetId} );
        
        my $assignedTo = $ticket->get("assignedTo");
        if ($assignedTo) {
           my $u = WebGUI::User->new($session,$assignedTo);
           $assignedTo = $u->username;
        }
        else {
           $assignedTo = "unassigned";
        }

        # Populate the required fields to fill in
        my %fields      = (
            ticketId      => $ticket->get("ticketId"),
            url           => $ticket->getUrl,
            title         => $ticket->get( "title" ),
            createdBy     => WebGUI::User->new($session,$ticket->get( "createdBy" ))->username,
            creationDate  => $session->datetime->epochToSet($ticket->get( "creationDate" )),
            assignedTo    => $assignedTo,
            ticketStatus  => $self->getStatus($ticket->get( "ticketStatus" )),
        );

        push @{ $ticketInfo->{ tickets } }, \%fields;
    }
    
    $session->http->setMimeType( 'application/json' );
    return encode_json( $ticketInfo );
}


#-------------------------------------------------------------------
# Everything below here is to make it easier to install your custom
# wobject, but has nothing to do with wobjects in general
#-------------------------------------------------------------------
# cd /data/WebGUI/lib
# perl -MWebGUI::Asset::Wobject::HelpDesk -e install www.example.com.conf [ /path/to/WebGUI ]
# 	- or -
# perl -MWebGUI::Asset::Wobject::HelpDesk -e uninstall www.example.com.conf [ /path/to/WebGUI ]
#-------------------------------------------------------------------


use base 'Exporter';
our @EXPORT = qw(install uninstall upgrade);
use WebGUI::Session;

#-------------------------------------------------------------------
sub install {
	my $config              = $ARGV[0];
	my $home                = $ARGV[1] || "/data/WebGUI";
    my $helpDeskTemplateDir = $ARGV[2] || "$home/docs/HelpDesk/templates";
    my $ticketTemplateDir   = $ARGV[3] || "$home/docs/HelpDesk/Ticket/templates";

    my $className = "WebGUI::Asset::Wobject::HelpDesk";
    unless ($home && $config) {
	    die "usage: perl -M$className -e install yoursite.conf\n";
	}
    
    print "Installing asset.\n";
	my $session = WebGUI::Session->open($home, $config);
    
    #Add wobject to config file
	$session->config->addToArray("assets",$className);

    #Create database tables
    $session->db->write("CREATE TABLE HelpDesk (
        assetId VARCHAR(22) BINARY NOT NULL,
        revisionDate BIGINT NOT NULL,
        viewTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000001',
        viewMyTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000002',
        viewAllTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000003',
        searchTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000004',
        manageMetaTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000005',
        editMetaFieldTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000006',
        editTicketTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000001',
        viewTicketTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000002',
        viewTicketRelatedFilesTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000003',
        viewTicketUserListTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000004',
        viewTicketCommentsTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000005',
        richEditIdPost VARCHAR(22) BINARY NOT NULL default 'PBrichedit000000000002',
        groupToPost VARCHAR(22) BINARY NOT NULL default '3',
        PRIMARY KEY (assetId,revisionDate)
    )");

    $session->db->write("CREATE TABLE HelpDesk_metaField (
        fieldId VARCHAR(22) BINARY NOT NULL,
        assetId VARCHAR(22) BINARY NOT NULL,
        label VARCHAR(100) DEFAULT NULL,
        dataType VARCHAR(20) DEFAULT NULL,
        required TINYINT(4) DEFAULT 0,
        searchable TINYINT(4) DEFAULT 0,
        possibleValues TEXT,
        defaultValues TEXT,
        hoverHelp TEXT,
        sequenceNumber INT(5) DEFAULT NULL,
        PRIMARY KEY  (fieldId)
    )");

    $session->db->write("CREATE TABLE Ticket (
        assetId VARCHAR(22) BINARY NOT NULL,
        revisionDate BIGINT NOT NULL,
        ticketId mediumint not null,
        severity VARCHAR(30) NOT NULLs,
        ticketStatus VARCHAR(30) NOT NULL default 'new';
        assigned tinyint(1) NOT NULL default 0,
        assignedTo VARCHAR(22) default NULL,
        assignedBy VARCHAR(22) default NULL,
        dateAssigned BIGINT default NULL,
        storageId VARCHAR(22) default NULL,
        internalComments longtext default NULL,
        solutionSummary longtext default NULL,
        comments longtext default NULL,
        averageRating float default 0,
        PRIMARY KEY (assetId,revisionDate)
    )");

    $session->db->write("CREATE TABLE Ticket_metaData (
        fieldId VARCHAR(22) BINARY NOT NULL,
        assetId VARCHAR(22) BINARY NOT NULL,
        value MEDIUMTEXT DEFAULT NULL,
        PRIMARY KEY  (fieldId, assetId)
    )");
    
    #Create row in incrementer table
    $session->db->write("insert into incrementer (incrementerId,nextValue) values ('ticketId',1)");
    
    ### Create a folder asset to store the default template
	my $importNode = WebGUI::Asset->getImportNode($session);
	my $helpFolder = $importNode->addChild({
		className=>"WebGUI::Asset::Wobject::Folder",
		title => "HelpDesk",
		menuTitle => "HelpDesk",
		url=> "help_desk",
		groupIdView=>"3"
	},"HelpDeskFolder00000001");
	
    my $ticketFolder = $helpFolder->addChild({
		className=>"WebGUI::Asset::Wobject::Folder",
		title => "Ticket",
		menuTitle => "Ticket",
		url=> "ticket",
		groupIdView=>"3"
	},"TicketFolder0000000001");

	my $tag = WebGUI::VersionTag->new($session, WebGUI::VersionTag->getWorking($session)->getId);
    if (defined $tag) {
	   print "Committing tag\n";
	   $tag->set({comments=>"Folder created by Asset Install Process"});
	   $tag->requestCommit;
	}
	
	### Install the help desk templates
	importTemplates($session,$helpDeskTemplateDir,$helpFolder);
	
    ### Install the ticket templates
    importTemplates($session,$ticketTemplateDir,$ticketFolder);

	$session->var->end;
	$session->close;
	print "Done. Please restart Apache.\n";
}

#-------------------------------------------------------------------
sub uninstall {
    my $config    = $ARGV[0];
	my $home      = $ARGV[1] || "/data/WebGUI";

    my $className = "WebGUI::Asset::Wobject::HelpDesk";
    
    unless ($home && $config) {
	    die "usage: perl -M$className -e uninstall yoursite.conf\n";
    }
    
	print "Uninstalling asset.\n";
	my $session = WebGUI::Session->open($home, $config);
    
    #Delete wobject from config file
	$session->config->deleteFromArray("assets",$className);
    
    #Delete all assets and default templates
	my $rs = $session->db->read(qq|
        select 
            assetId 
        from 
            asset 
        where 
            className='$className' 
            or assetId like 'HELPDESK%' or assetId like 'TICKET%'|
    );
	while (my ($id) = $rs->array) {
        print "purging asset $id\n";
        my $asset = WebGUI::Asset->newByDynamicClass($session, $id);
        $asset->purge if defined $asset;
	}
    
    #Drop asset related tables
	$session->db->write("drop table if exists HelpDesk");
    $session->db->write("drop table if exists Ticket");
    
	$session->var->end;
	$session->close;
	print "Done. Please restart Apache.\n";
}

#-------------------------------------------------------------------
sub upgrade {
	my $config = $ARGV[0];
	my $home = $ARGV[1] || "/data/WebGUI";
	my $helpDeskTemplateDir = $ARGV[2] || "$home/docs/HelpDesk/templates";
    my $ticketTemplateDir   = $ARGV[3] || "$home/docs/HelpDesk/Ticket/templates";

    unless ($home && $config) {
	    die "usage: perl -MWebGUI::Asset::Wobject::HelpDesk -e upgrade yoursite.conf\n";
	}
    print "Updating asset.\n";
	my $session = WebGUI::Session->open($home, $config);
	$session->user({userId=>3});
    
    my $helpDeskFolder = WebGUI::Asset->new($session,"HelpDeskFolder00000001");
	importTemplates($session,$helpDeskTemplateDir,$helpDeskFolder);
    
    my $ticketFolder   = WebGUI::Asset->new($session,"TicketFolder0000000001");
	importTemplates($session,$ticketTemplateDir,$ticketFolder);

    $session->var->end;
	$session->close;
	print "Done.\n";
}

#-----------------------------------------------------------------
sub importTemplates {
    my $session = shift;
    my $templateDir = shift;
    my $folder = shift;
   
    my $quiet = 0;
    return 0 unless (opendir (DIR,$templateDir));
    my $slash;

    if ($^O =~ /^Win/i || $^O =~ /^MS/i) {
        $slash = "\\";
    } else {
        $slash = "/";
    }
   
    my @files=readdir(DIR);
    closedir(DIR);
    foreach my $file (@files) {
        next if ($file eq "." || $file eq ".." || !isValidTemplateFile($file));
	    my $pathToFile = $templateDir.$slash.$file;
	    unless ( open (FILE, $pathToFile) ) {
	        print "Could not open $pathToFile.  Skipping Template $!\n" unless ($quiet);
	        next;
	    }
	  
	    my $title        = "Default Template";
	    my $namespace    = q{};
	    my $assetId      = q{};
        my $settingId    = q{};
	    my $templateFile = q{};
        my $headBlock    = q{};
	    my $head         = 0;
	  
	    while (<FILE>) {
	        my $line = $_;
		    my $char = "#";
		    if($line =~ m/^$char[^=<]+=/){
		        my $setting = substr($line,1);
			    my ($key,$value) = split("=",$setting);
                $key = lc($key);
            
                if($key eq "namespace") {
                    $namespace = trim($value);
                } 
                elsif($key eq "title") {
                    $title = trim($value);
                } 
                elsif($key eq "assetid") {
			        $assetId = trim($value);
                }
                elsif($key eq "settingid") {
                    $settingId = trim($value);
                }
                next;
		    }
            elsif ($line =~ m/^~~~$/) {
		        $head = 1;
                next;
		    } 
            elsif ($head) {
		        $headBlock .= $line;
		    } 
            else {
		        $templateFile .= $line;	
            }
	    }
	  
	    if($assetId eq "") {
	        print "No Asset Id specified.  Skipping Template $file\n" unless ($quiet);
		    next;
	    }
	  
        unless(isValidAssetId($assetId)) {
	        print "Skipping $file.  Invalid assetId\n" unless ($quiet);
            next;
        }
	  
        if($namespace eq "") {
	        print "No Namespace specified.  Skipping Template $file\n" unless ($quiet);
            next;
        }
	  
        print "Processing Asset $assetId\n" unless ($quiet);
	  
        my $tmpl = WebGUI::Asset::Template->new($session,$assetId);
        if($tmpl){
	        print "Asset $assetId found.  Updating ... \n" unless ($quiet);
	        $tmpl->update({
		        template  =>$templateFile,
                headBlock =>$headBlock,
			    namespace =>$namespace,
		        title     =>$title,
                menuTitle =>$title
            });
        } 
        else {
            print "Asset $assetId not found.  Creating ... \n" unless ($quiet);
            $folder->addChild({ 
                className   =>"WebGUI::Asset::Template",
                namespace   =>$namespace,
	            title       =>$title,
	            menuTitle   =>$title,
	            ownerUserId =>"3",
	            groupIdView =>"7",
	            groupIdEdit =>"4",
                isHidden    =>1, 
                template    =>$templateFile,
                headBlock   =>$headBlock,
            }, $assetId);   	  
        }
      
        #Set the asset Id in the settings table if set
        if($settingId) {
            my ($exists) = $session->db->quickArray("select count(*) from settings where name=?",[$settingId]);
            if($exists) {
                $session->setting->set($settingId,$assetId);
            } 
            else {
                $session->setting->add($settingId,$assetId);
            }
        }
	  
	    my $tag = WebGUI::VersionTag->new($session, WebGUI::VersionTag->getWorking($session)->getId);
        if (defined $tag) {
	        print "Committing tag\n";
	        $tag->set({comments=>"Template added/updated by Asset Install Process"});
	        $tag->requestCommit;
	    }
    }
    return 1;
}

#-----------------------------------------------------------------
sub isValidTemplateFile {
    my $filename = $_[0];
    my $quiet = 0;
    unless ($filename =~ m/(.*)\.(.*?)$/) {
        print "Skipping $filename.  Invalid File Format\n";
        return 0;
    }
    my $extension = $2;
   
    unless (lc($extension) eq "tmpl") {
        print "Skipping $filename.  Invalid template extension\n" unless ($quiet);
        return 0;
    }   
    return 1;
}

#-----------------------------------------------------------------
sub isValidAssetId {
    my $assetId = $_[0];
    unless (length($assetId) <= 22) {
        return 0;
    }
    return 1;
}

#-----------------------------------------
sub trim {
    my $string = $_[0];
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}



1;
