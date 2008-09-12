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

#-------------------------------------------------------------------

=head2 getAverageRatingImage

   This method returns the average rating image based on the rating passed in

=cut

sub getAverageRatingImage {
	my $self   = shift;
    my $rating = shift || $self->get("averageRating");
    return  $self->session->url->extras("wobject/HelpDesk/stars_white/0.gif") unless ($rating);
    #Multiply Rating by 10
    $rating *= 10;    
    #Round to two digit integer
    my $imageId = int(sprintf("%2f", $rating));

    return $self->session->url->extras("wobject/HelpDesk/stars_white/".$imageId.".gif");
}

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
		internalComments => {
            fieldType    =>"HTMLArea",
            defaultValue =>undef
        },
        ticketStatus => {
            fieldType    =>"selectBox",
            defaultValue => "new"
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
			noFormPost		=> 1,
			fieldType       => "hidden",
			defaultValue    => [],
		},
        averageRating => {
			noFormPost		=> 1,
			fieldType       => "hidden",
			defaultValue    => 0,
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
sub get {
	my $self = shift;
	my $param = shift;
	if ($param eq 'comments') {
		return decode_json($self->SUPER::get('comments')||'[]');
	}
	return $self->SUPER::get($param, @_);
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

#-------------------------------------------------------------------
sub i18n {
	my $self    = shift;
    my $session = $self->session;
    
    unless ($self->{_i18n}) { 
        $self->{_i18n} = WebGUI::International->new($session, "Asset_Ticket");
    }
    return $self->{_i18n};
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
    my $ticketId = $self->get("ticketId");    
    if ( $form->get('assetId') eq "new" ) {
        $ticketId = $session->db->getNextId("ticketId");
        
    }

    $self->update( {
        url      => $session->url->urlize( join "/", $self->getParent->get('url'), $ticketId ),
        ticketId => $ticketId     
    } );

    #update the Ticket meta data
    foreach my $props (@metadata) {
        $db->write(
            "replace into Ticket_metaData (fieldId,assetId,value) values (?,?,?)",
            [$props->{fieldId},$assetId,$props->{value}]
        );
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

#-------------------------------------------------------------------
sub update {
    my $self = shift;
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
	$self->SUPER::update($properties, @_);
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
            "meta_field_label" => $metafields->{$fieldId}->{label},
            "meta_field_value" => $fieldValue,
        });
    }
    $var->{'meta_field_loop'} = \@metaDataLoop;

    #Get a new copy of the available statuses hashref
    tie my %statusHash, "Tie::IxHash";
    %statusHash = %{$parent->getStatus};
    #Remove the new element so users can't set the status back to new
    delete $statusHash{'new'};              
    @{$var->{'status_loop'}} = map { { 'status_key'=>$_, 'status_value'=>$statusHash{$_} } } keys %statusHash;


    #Create URLs for post backs
    $var->{'url_postFile'     } = $self->getUrl('func=uploadFile');
    $var->{'url_listFile'     } = $self->getUrl('func=fileList');
    $var->{'url_userSearch'   } = $self->getUrl('func=userSearch');
    $var->{'url_changeStatus' } = $self->getUrl('func=setStatus');
    $var->{'url_postSolution' } = $self->getUrl('func=postSolution');
    $var->{'url_postComment'  } = $self->getUrl('func=postComment');
    $var->{'url_getComment'   } = $self->getUrl('func=getComments');    

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

    #Add controls for people who can post
    if($var->{'canPost'}) {
        #Post Files
        $var->{ 'file_form_start'     } 
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=uploadFile'),
                extras  => q{id="fileUploadForm"}
            });
        $var->{ 'file_form_end'       } = WebGUI::Form::formFooter( $session );
        
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
                imagePath      =>"wobject/HelpDesk/stars_white/",
                imageExtension =>"gif",
                defaultRating  => "0"
            });
        $var->{ 'comments_form_end'   } = WebGUI::Form::formFooter( $session );
    }
    
    #Add controls for people who can edit
    if($var->{'canEdit'}) {
        $var->{ 'userSearch_form_start'} 
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=userSearch'),
                extras  => q{id="userSearchForm"}
            });
        $var->{ 'userSearch_form_end'} = WebGUI::Form::formFooter( $session );

        $var->{'solution_form_start'  }
            = WebGUI::Form::formHeader( $session, {
                action  => $self->getUrl('func=postSolution'),
                extras  => q{id="postSolutionForm"}
            });
        $var->{'solution_form_end'    } = WebGUI::Form::formFooter( $session );
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

This page is only available to those who can edit this Photo.

=cut

sub www_edit {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $self->session->form;
    my $parent  = $self->getParent;

    return $self->session->privilege->insufficient  unless $self->canEdit;
    return $self->session->privilege->locked        unless $self->canEditIfLocked;

    # Prepare the template variables
    my $var     = {};
    
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
    
    $var->{ form_keywords }
        = WebGUI::Form::Text( $session, {
            name        => "keywords",
            value       => ( $form->get("keywords") || $self->get("keywords") ),
        });

    #$var->{ form_severity }
    #    = WebGUI::Form::SelectBox( $session, {
    #        name         => "severity",
    #        options      => $self->getSeverity,
    #        value        => ( $form->get("severity") || $self->get("severity") ),
    #    });

    
    $var->{ form_internalComments }
        = WebGUI::Form::HTMLArea( $session, {
            name        => "internalComments",
            value       => ( $form->get("internalComments") || $self->get("internalComments") ),
            richEditId  => $self->getParent->get("richEditIdPost"),
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
        $comment->{'rating_image'      } = $session->url->extras('wobject/HelpDesk/stars/'.$comment->{rating}.'.gif');
        $comment->{'comment'           } = WebGUI::HTML::format($comment->{comment},'text');
    }
    
    return $self->processTemplate(
        $var,
        $parent->get("viewTicketCommentsTemplateId")
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
    
    my @errors    = ();

    $session->http->setMimeType( 'application/json' );
   
    #Check for errors
    unless ($self->getParent->canPost) {
        push(@errors,'You do not have permission to post a comment to this ticket');
    }

    if($form->get("comment") eq "") {
        push(@errors,'You have entered an empty comment');
    }

    if(scalar(@errors)) {
        my $errorHash = {
            hasError =>"true",
            errors   =>\@errors
        };
        return encode_json( $errorHash );
    }

    #Post the comment
    my $comment = $form->process('comment','textarea');
    WebGUI::Macro::negate(\$comment);
    my $rating = $form->process('rating','commentRating',"0", { defaultRating  => "0" });
	
    my $comments = $self->get('comments');

	push @$comments, {
		alias		=> $user->profileField('alias'),
		userId		=> $user->userId,
		comment		=> $comment,
		rating		=> $rating,
		date		=> time(),
		ip			=> $self->session->var->get('lastIP'),
	};
	
    my $count = 1;
    my $sum = 0;
    map { $sum += $_->{rating}; $count++ if($_->{rating} > 0); } @{$comments};

    my $avgRating = $sum/$count;
	$self->update({ comments=>$comments, averageRating=> $avgRating});
    my $imgSrc    = $self->getAverageRatingImage($avgRating);
    $avgRating    = sprintf("%.1f", $avgRating);
    #$user->karma(3, $self->getId, 'Left comment for Bazaar Item '.$self->getTitle);

	#$self->notifySubscribers(
	#	$self->session->user->profileField('alias') .' said:<br /> '.WebGUI::HTML::format($comment,'text'),
	#	$self->getTitle . ' Comment',
	#	$user->profileField('email')
	#	);

    return "{ averageRating:'$avgRating', averageRatingImage:'$imgSrc'}";
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
        push(@errors,'You do not have permission to post a solution to thic ticket');
    }

    if(scalar(@errors)) {
        my $errorHash = {
            hasError =>"true",
            errors   =>\@errors
        };
        return encode_json( $errorHash );
    }

    my $hash = { solutionSummary  => $solution };
    $self->update($hash);
    
    return encode_json( $hash );
}


#----------------------------------------------------------------------------

=head2 www_setAssignment ( ) 

Properly sets who the ticket is assigned to.

=cut

sub www_setAssignment {
    my $self      = shift;
    my $session   = $self->session;
    
    unless ($self->getParent->canEdit) {
        return "{
            hasError: true,
            errors: ['You do not have permission to assign this ticket']
        }";
    }

    my $assignedTo = $session->form->get("assignedTo");
    
    unless ($assignedTo) {
        return "{
            hasError: true,
            errors: ['You have not chosen someone to assign this ticket to.']
        }";
    }
    
    my $currentUser   = $session->user->userId;
    my $dateAssigned  = $session->datetime->time();
    my $formattedDate = $session->datetime->epochToSet($dateAssigned);
    my $username      = WebGUI::User->new($session,$assignedTo)->username;
    my $assignedBy    = WebGUI::User->new($session,$currentUser)->username;

    $self->update({
        assigned     => 1,
        assignedTo   =>$assignedTo,
        assignedBy   =>$currentUser,
        dateAssigned =>$dateAssigned
    });

    return "{ assignedTo:'$username', dateAssigned:'$formattedDate', assignedBy:'$assignedBy' }";
}

#----------------------------------------------------------------------------

=head2 www_setStatus ( ) 

Properly sets the current status of a ticket.

=cut

sub www_setStatus {
    my $self      = shift;
    my $session   = $self->session;

    my $status    = $session->form->get("status");
    my @errors    = ();

    $session->http->setMimeType( 'application/json' );
   
    unless ($self->getParent->canEdit) {
        push(@errors,'You do not have permission to assign this ticket');
    }
    unless ($status) {
        push(@errors,'You have not chosen a status for this ticket.');
    }
    if($status eq "new") {
        push(@errors,'You cannot change the status of a ticket to new');    
    }

    if(scalar(@errors)) {
        my $errorHash = {
            hasError =>"true",
            errors   =>\@errors
        };
        return encode_json( $errorHash );
    }

    $self->update({ ticketStatus  => $status });
    my $formattedStatus = $self->getParent->getStatus($status);

    return "{ status:'$formattedStatus' }";
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

