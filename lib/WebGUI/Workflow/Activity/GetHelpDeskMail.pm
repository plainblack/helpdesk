package WebGUI::Workflow::Activity::GetHelpDeskMail;


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
use base 'WebGUI::Workflow::Activity';
use WebGUI::Mail::Get;
use WebGUI::Mail::Send;
use WebGUI::Asset;
use WebGUI::HTML;
use WebGUI::International;
use WebGUI::User;
use WebGUI::Utility;
use WebGUI::HTML;
use HTML::Parser;

=head1 NAME

Package WebGUI::Workflow::Activity::GetHelpDeskMail

=head1 DESCRIPTION

Retrieve the incoming mail messages for a Help Desk

=head1 SYNOPSIS

See WebGUI::Workflow::Activity for details on how to use any activity.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 definition ( session, definition )

See WebGUI::Workflow::Activity::defintion() for details.

=cut 

sub definition {
	my $class      = shift;
	my $session    = shift;
	my $definition = shift;
	my $i18n       = WebGUI::International->new($session, "Asset_HelpDesk");
	
    push(@{$definition}, {
		name       =>$i18n->get("get hd mail"),
		properties => { }
	});
	return $class->SUPER::definition($session,$definition);
}


#-------------------------------------------------------------------

=head2 execute (  )

See WebGUI::Workflow::Activity::execute() for details.

=cut

sub execute {
	my $self     = shift;
    my $hd       = shift;

    my $session  = $self->session;
    my $log      = $session->log;	
    my $i18n     = WebGUI::International->new($session, "Asset_HelpDesk");

    my $ttl      = $self->getTTL();
    my $complete = $self->COMPLETE;

    return $complete unless ($hd->get("getMail"));
    
	my $start = time();
	my $mail  = WebGUI::Mail::Get->connect($session,{
		server   =>$hd->get("mailServer"),
		account  =>$hd->get("mailAccount"),
		password =>$hd->get("mailPassword")
	});

    unless (defined $mail) {
        $log->warn("Could not connect to mail server ".$hd->get("mailServer").".  Please check your account settings");
        return $complete;
    }

    #Set up some variables outside the loop
	my $postGroup           = $hd->get("groupToPost"); #group that's allowed to post to the Help Desk
    my $listAddress         = $hd->get("mailAddress");
    my $listPrefix          = $hd->get("mailPrefix");
    my $autosubscribe       = $hd->get("autoSubscribeToTicket");
    my $requireSubscription = $hd->get("requireSubscriptionForEmailPosting");

    my $rejectedMsg         = $i18n->get("rejected");
    my $noAccountMsg        = $i18n->get("rejected because no user account");
    my $notAllowedMsg       = $i18n->get("rejected because not allowed");
    my $noSubscribeMsg      = $i18n->get("rejected because no subscription");
    my $noReplyToMsg        = $i18n->get("rejected because no replyToFound");

	while (my $message = $mail->getNextMessage) {
        #Restore the admin user
        $session->user({userId=>3});
		next unless (scalar(@{$message->{parts}})); # no content, skip it
		
        my $from      = $message->{from};
        my $subject   = $message->{subject};
        my $messageId = $message->{messageId};

        my $userEmail = "";
        my $userEmail = $1 if ($from =~ /<(\S+\@\S+)>/);  #Remove the brackets from the email address
        my $user      = WebGUI::User->newByEmail($session, $userEmail); #instantiate the user by email
        
		unless (defined $user) { #if no user
			unless ($postGroup eq 1 || $postGroup eq 7) { #reject mail if no registered email, unless post group is Visitors (1) or Everyone (7)
				if ($from eq "") {
					$log->error("For some reason the message ".$subject." (".$messageId.") has no from address.");
				}
				elsif ($from eq $listAddress) {
					$log->error("For some reason the message ".$subject." (".$messageId.") has the same from address as the help desks's mail address.");
				} 
				else {
                    $message->{'subject'    } = $listPrefix.$rejectedMsg." ".$subject;
                    $message->{'listAddress'} = $listAddress;
                    $message->{'error'      } = $noAccountMsg;
					$self->sendErrorMail($message);
                }
				next;
			}
			$user = WebGUI::User->new($session, undef); # instantiate the user as a visitor
		}

        #Update the user in session
        $session->user({userId=>$user->userId});
        
        #Return an error unless the user can post to the thread
        unless ($user->isInGroup($postGroup)) {
            $message->{'subject'    } = $listPrefix.$rejectedMsg." ".$subject;
            $message->{'listAddress'} = $listAddress;
            $message->{'error'      } = $noAccountMsg;
			$self->sendErrorMail($message);
            next;
        }

		my $ticket       = undef;
        my $userId       = $user->userId;
        my $isSubscribed = $hd->isSubscribed($userId); #subscribed to the help desk?

        #Handle replies to a CS that are still coming i
        if ($message->{inReplyTo} && $message->{inReplyTo} =~ m/cs\-([\w_-]{22})\@/) {
			my $id = $1;
            #Look up the mapping to the ticketId
            my ($ticketId) = $db->quickArray("select mapToAssetId from Ticket_collabRef where origAssetId=?",[$id]);
            if($ticketId) {
                $ticket = WebGUI::Asset->newByDynamicClass($session, $ticketId);
                $isSubscribed = $isSubscribed || $ticket->isSubscribedToTicket($userId);  #subscribed to the ticket?
            }
		}

        if ($message->{inReplyTo} && $message->{inReplyTo} =~ m/ticket\-([\w_-]{22})\@/) {
			my $id = $1;
			$ticket = WebGUI::Asset->newByDynamicClass($session, $id);
            $isSubscribed = $isSubscribed || $ticket->isSubscribedToTicket($userId);  #subscribed to the ticket?
		}

        #Return an error if subscriptions are required and the user is not subscribed to the ticket or the help desk
        if($requireSubscription && !$isSubscribed) {
            $message->{'subject'    } = $listPrefix.$rejectedMsg." ".$subject;
            $message->{'listAddress'} = $listAddress;
            $message->{'error'      } = $noSubscribeMsg;
            $self->sendErrorMail($message);
            next;
        }
        
		if (defined $ticket) { #Reply to a ticket
			#Add a comment to the ticket if the user can post to it
            my ($content,$attachments) = $self->processMessageParts($message->{parts});
            $ticket->postComment($content,{ user => $user });

            #Add attachments
            $self->postAttachments($attachments,$ticket);
            
            #subscribe poster to thread if set to autosubscribe, and they're not already            
			if ($autosubscribe && !$isSubscribed && $hd->canSubscribe($userId)) {
				$ticket->subscribe($userId);
			}
		}
        else { #A new ticket
			#Scrub the subject since it becomes the title
            $message->{subject} = $self->scrubTitle($message->{subject},$listPrefix);
            #Add a new ticket to the help desk which will auto subscribe them regardless of the setting
            $self->postNewTicket($message,$hd,$user);
		}
		# just in case there are a lot of messages, we should release after a minutes worth of retrieving
		if (time() > $start + $ttl) {
            $session->user({userId=>3}); #Restore the admin session
            last ;
        }
	}
	$mail->disconnect;
	return $complete;
}

#-------------------------------------------------------------------

=head2 postAttachments (attachments, ticket )

Posts any attachments to the ticket

=head3 attachments

The messageParts to process

=head3 ticket

The ticket to post the attachments to

=cut

sub postAttachments {
    my $self        = shift;
    my $attachments = shift;
    my $ticket      = shift;

    return unless scalar(@{$attachments});

	my $store  = $ticket->getStorageLocation;  #Get the storage location
    foreach my $file (@{$attachments}) {
		my $filename = $file->{filename};
		unless ($filename) {
			$file->{type} =~ m/\/(.*)/;
			my $type      = $1;
			$filename     = $self->session->id->generate.".".$type;
		}	
		$store->addFileFromScalar($filename, $file->{content});
	}
}

#-------------------------------------------------------------------

=head2 postNewTicket ( message, hd, user )

Posts the comment

=head3 the message

The message ref to scrub

=cut

sub postNewTicket {
    my $self      = shift;
    my $session   = $self->session;
    my $message   = shift;
    my $hd        = shift;
    my $user      = shift;
    
    my ($content,$attachments) = $self->processMessageParts($message->{parts});
	    
    #Get the next ticket Id
    my $ticketId   = $session->db->getNextId("ticketId");
    #Set the karma scale    
    my $karmaScale = 1;
    if($hd->{karmaEnabled}) {
        $karmaScale = $hd->get("defaultKarmaScale");
    }

    #Post the ticket to the help desk
    my $ticket     = $hd->addChild({
        className     =>"WebGUI::Asset::Ticket",
        title         => $message->{subject},
        menuTitle     => $message->{subject},
        url           => $session->url->urlize( join "/", $hd->get('url'), $ticketId ),
        ownerUserId   => $user->userId,
        synopsis      => $content,
        ticketId      => $ticketId,
        ticketStatus  => "pending",
        karmaScale    => $karmaScale
    });

    #Automatically subscribe the user posting the ticket - this also creates the subscription group
    $ticket->subscribe($user->userId);
    
    #Log the history
    $ticket->logHistory("Ticket created via email",$user);

    #Add attachments
    $self->postAttachments($attachments,$ticket);
    
    #Request Autocommit
    $ticket->requestAutoCommit;

	return;
}

#-------------------------------------------------------------------

=head2 processMessageParts( messageParts )

Processes the message parts and returns an array ref of attachments and the content

=head3 messageParts

The messageParts to process

=cut

sub processMessageParts {
    my $self         = shift;
    my $messageParts = shift;
    my @attachments  = ();
	my $content      = "";
	
    foreach my $part (@{$messageParts}) {
		if (($part->{type} =~ /^text\/plain/ || $part->{type} =~ /^text\/html/) && $part->{filename} eq "") {
			my $text = $part->{content};
			if ($part->{type} eq "text/plain") {
				$text = WebGUI::HTML::filter($text, "all");
				$text = WebGUI::HTML::format($text, "text");
			} 
            elsif ($part->{type} eq 'text/html') {
                $text = $self->scrubHTML($text);
            }
			$content .= $text;
		} else {
			push(@attachments, $part);
		}
	}

    return ($content, \@attachments);
}

#-------------------------------------------------------------------

=head2 scrubHTML ( html )

Takes the message and tries to return just the content that should be posted removing replyto blocks and unecessary HTML

=head3 html

The html segment you want to convert to text.

=cut

sub scrubHTML {
    my $self     = shift;
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
            || ($tag eq "table" && $attr->{id} eq "hd_notification"))
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


#-------------------------------------------------------------------

=head2 scrubTitle ( text, prefix )

Takes the title and scrubs out things like "re:" and the message prefix

=head3 text

The text you want to scrub.

=head3 prefix

Prefix to scrub out.

=cut

sub scrubTitle {
	my $self   = shift;
    my $title  = shift;
    my $prefix = shift || "";    

    $title =~ s/\Q$prefix//;
    if ($title =~ m/re:/i) {
        $title =~ s/re://ig;
        $title = "Re: ".$title;
        $title =~ s/\s+/ /g;
    } 
    
    return $title;
}

#-------------------------------------------------------------------

=head2 sendErrorMail (  )

Sends an error email

=cut

sub sendErrorMail {
    my $self       = shift;
	my $session    = $self->session;
    my $message    = shift;
    my $send = WebGUI::Mail::Send->create($session, {
		to        => $message->{'from'},
		inReplyTo => $message->{'messageId'},
		subject   => $message->{'subject'},
		from      => $message->{'listAddress'}
	});
	$send->addText($message->{'error'});
	$send->send;
}


1;


