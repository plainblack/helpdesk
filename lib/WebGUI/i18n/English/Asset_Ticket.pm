package WebGUI::i18n::English::Asset_Ticket;
use strict;

our $I18N = {
	'assetName' => {
        message => q|Ticket|,
        context => q|label for Ticket, getName|,
        lastUpdated => 1128640132,
    },

    'subscribe_link' => {
        message => q{Subscribe},
        lastUpdated => 1122316558,
        context => q|Label for the subscribe link on the ticket page.|,
    },
    'unsubscribe_link' => {
        message => q{Unsubscribe},
        lastUpdated => 1122316558,
        context => q|Label for the unsubscribe link on the ticket page.|,
    },
    'new_ticket_message' => {
        message => q{A new ticket has been added to one of your subscriptions.},
        lastUpdated => 1122316558,
        context => q|text to tell user that a new ticket has been added to a subscription|,
    },
    'update_ticket_message' => {
        message => q{One of the tickets you are subscribed to has been updated.},
        lastUpdated => 1122316558,
        context => q|Text to notify user that a ticket has been updated.|,
    },
    'notification_assignment_subject' => {
        message => q{Ticket Assignment Notification},
        lastUpdated => 1122316558,
        context => q|TODO|,
    },
    'notification_assignment_message' => {
        message => q{You have been assigned to handle the ticket entitled<br /><br /> <a href="%s">%s</a>.<br /><br />Please look into this as soon as you are able},
        lastUpdated => 1122316558,
        context => q|text to notify user that they have been assigned a ticket, first param is ticket URL second is ticket title.|,
    },
    'notification_unassignment_message' => {
        message => q{You are no longer assigned to the ticket entitled<br /><br /> <a href="%s">%s</a>},
        lastUpdated => 1122316558,    
        context => q|Text to notify user that the given ticket is no longer assigned to them, first param is URL second is ticket title.|,
    },
    'notification_owner_assignment_message' => {
        message => q{The ticket you submitted entitled <a href="%s">%s</a> has been assigned to %s},
        lastUpdated => 1122316558,
        context => q|Text to notify user that the ticket they subitted as been assigned, 3 parameters are: ticket URL, title, and assigned username|,
    },
    'notification_new_file_message' => {
        message => q{A new file has been uploaded to this ticket},
        lastUpdated => 1122316558,
        context => q|Notify user that a new file has ben attached to their ticket.|,
    },
    'notification_status_message' => {
        message => q{This ticket now has a status of %s with the following comment},
        lastUpdated => 1122316558,
        context => q|Notify user od new status assigned to their ticket, parameter is status name|,
    },
    'post' => {
		message => q|Post|,
		lastUpdated => 0,
		context => q|Label for comment post buttin.|
	},
    'reopen ticket' => {
		message => q|Reopen Ticket|,
		lastUpdated => 0,
		context => q|Label for button that reopens a ticket|
	},
    'comments' => {
		message => q|Comments|,
		lastUpdated => 0,
		context => q|Label for the comments field in the edit ticket form.|
	},
    'solution summary' => {
		message => q|Solution Summary|,
		lastUpdated => 0,
		context => q|Label for the summary field in the edit ticket form.|
	},
    'close tab' => {
		message => q|Close Tab|,
		lastUpdated => 0,
		context => q|Title text for close tab button; displayed as a hint.|
	},
    'assign to me' => {
        message => q{Assign To Me},
        lastUpdated => 0,
        context => q|Click here to assign the ticket to yourself.|,
    },
    'unassign' => {
        message => q{Unassign},
        lastUpdated => 0,
        context => q|The user clicks this to change an assigned ticket to unassigned.|,
    },
    'change' => {
        message => q{Change},
        lastUpdated => 0,
        context => q|Click here to change the value of the field|,
    },
    'title required' => {
        message => q{Title is a required field},
        lastUpdated => 0,
        context => q|This is an error message to remind the user to enter a title on the ticket|,
    },
    'synopsis required' => {
        message => q{Description is a required field},
        lastUpdated => 0,
        context => q|This is an error message to remind the user to enter a description on the ticket|,
    },
    'close tab' => {
                message => q|Close Tab|,
                lastUpdated => 0,
                context => q|label for link to close ticket tab in help desk main view|
        },
    'confirm and close' => {
                message => q|Confirm and Close|,
                lastUpdated => 0,
                context => q|Label for 'confirm mand close' button.|
        },
#    'TODO' => {
#        message => q{TODO},
#        lastUpdated => 0,
#        context => q|TODO|,
#    },
};

1;
