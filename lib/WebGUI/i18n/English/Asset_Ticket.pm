package WebGUI::i18n::English::Asset_Ticket;
use strict;

our $I18N = {
	'assetName' => {
        message => q|Ticket|,
        context => q|label for Ticket, getName|,
        lastUpdated => 1128640132,
    },

    'subscribe_link' => {
        message => q{subscribe},
        lastUpdated => 1122316558,
    },
    'unsubscribe_link' => {
        message => q{unsubscribe},
        lastUpdated => 1122316558,
    },
    'new_ticket_message' => {
        message => q{A new ticket has been added to one of your subscriptions.},
        lastUpdated => 1122316558,
    },
    'update_ticket_message' => {
        message => q{One of the tickets you are subscribed to has been updated.},
        lastUpdated => 1122316558,
    },
    'notification_assignment_subject' => {
        message => q{Ticket Assignment Notification},
        lastUpdated => 1122316558,
    },
    'notification_assignment_message' => {
        message => q{You have been assigned to handle the ticket entitled<br /><br /> <a href="%s">%s</a>.<br /><br />Please look into this as soon as you are able},
        lastUpdated => 1122316558,
    },
    'notification_unassignment_message' => {
        message => q{You are no longer assigned to the ticket entitled<br /><br /> <a href="%s">%s</a>},
        lastUpdated => 1122316558,    
    },
    'notification_owner_assignment_message' => {
        message => q{The ticket you submitted entitled <a href="%s">%s</a> has been assigned to %s},
        lastUpdated => 1122316558,
    },
    'notification_owner_assignment_message' => {
        message => q{The ticket you submitted entitled <a href="%s">%s</a> has been assigned to %s},
        lastUpdated => 1122316558,
    },
    'notification_new_file_message' => {
        message => q{A new file has been uploaded to this ticket},
        lastUpdated => 1122316558,
    },
    'notification_status_message' => {
        message => q{This ticket now has a status of %s with the following comment},
        lastUpdated => 1122316558,
    },
};

1;
