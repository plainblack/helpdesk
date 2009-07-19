package WebGUI::i18n::English::Asset_HelpDesk;
use strict;

our $I18N = {
	'assetName' => {
        message     => q|Help Desk|,
        context     => q|label for Help Desk, getName|,
        lastUpdated => 1128640132,
    },
    'hoverHelp_possibleValues' => {
        message     => q{<p>This area should only be used in with the following form fields:
<br /><br />
Checkbox List<br />
Combo Box<br />
Hidden List<br />
Radio List<br />
Select Box<br />
Select List<br />
<br><br>
None of the other profile fields should use the Possible Values field as it will be ignored.<br />
If you do enter a Possible Values list, it MUST be formatted as follows
<pre>
key1|value1
key2|value2
key3|value3
...
</pre><br />
You simply replace key1|value1 with your own name/value pairs.},
        lastUpdated => 1132542146,
    },
    'hoverHelp_defaultValues' => {
        message     => q|<p>Default value you wish to display in the field.  For fields that can have multiple default values, list default values as mulitple line items</p>|,
        lastUpdated => 1122316558,
    },
    'subscribe_link' => {
        message     => q{subscribe},
        lastUpdated => 1122316558,
    },
    'unsubscribe_link' => {
        message     => q{unsubscribe},
        lastUpdated => 1122316558,
    },
    'require subscription for email posting' => {
		message     => q|Require subscription for email posts?|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'require subscription for email posting help' => {
		message     => q|If this is set to yes, then the user not only has to be in the group to post, but must also be subscribed to the help desk or ticket in order to post to it.|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
	'auto subscribe to ticket' => {
		message     => q|Auto subscribe to thread?|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'auto subscribe to ticket help' => {
		message     => q|If the user is not subscribed to a ticket, nor the help desk, and they post to the Help Desk via email, should the be subscribed to the ticket? If this is set to yes, they will be. Note that this option only works if the 'Require subscription for email posts?' field is set to 'no'.|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
    'mail server' => {
		message     => q|Server|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'mail server help' => {
		message     => q|The hostname or IP address of the mail server to fetch mail from.|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
    'mail account' => {
		message     => q|Account|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'mail account help' => {
		message     => q|The account name (username / email address) to use to log in to the mail server.|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
    'mail password' => {
		message     => q|Password|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'mail password help' => {
		message     => q|The password of the account to log in to the server with.|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
    'mail address' => {
		message     => q|Address|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'mail address help' => {
		message     => q|The email address that users can send messages to in order to post messages.|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
    'mail prefix' => {
		message     => q|Prefix|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'mail prefix help' => {
		message     => q|This string will be prepended to the subject line of all emails sent out from this help desk.|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
    'get mail' => {
		message     => q|Get mail?|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'get mail help' => {
		message     => q|Do you want to have this Help Desk fetch posts from an email account?|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
	'get mail interval' => {
		message     => q|Check Mail Every|,
		lastUpdated => 0,
		context     => q|field label for mail setting|
	},
	'get mail interval help' => {
		message     => q|How often should we check for mail on the server?|,
		lastUpdated => 0,
		context     => q|help for mail setting field label|
	},
    'approval workflow description' => {
        message     => q|Choose a workflow to be executed on each ticket as it gets submitted.|,
        lastUpdated => 0,
    },
    'approval workflow' => {
        message     => q|Ticket Approval Workflow|,
        lastUpdated => 0,
    },
    'rejected' => {
		message     => q|Rejected|,
		lastUpdated => 0,
		context     => q|prepended to subject line in rejection emails|
	},
	'rejected because no user account' => {
		message     => q|You are not allowed to post messages because we could not find your user account. Perhaps you do not have this email address associated with your user account.|,
		lastUpdated => 0,
		context     => q|rejection letter for posting when a user account could not be looked up|
	},
	'rejected because not allowed' => {
		message     => q|You are not allowed to post messages because you have insufficient privileges.|,
		lastUpdated => 0,
		context     => q|rejection letter for posting when not subscribed or not in group to post|
	},
    'rejected because no subscription' => {
		message     => q|You are not allowed to post messages to this ticket because you are not subscribed.  Please subscribe to the ticket and then try again.|,
		lastUpdated => 0,
		context     => q|rejection letter for posting when not subscribed|
	},
    'get hd mail' => {
		message => q|Get Help Desk Mail|,
		lastUpdated => 0,
		context => q|Title of Help Desk Mail workflow activity|
	},
    'close tab' => {
		message => q|Close Tab|,
		lastUpdated => 0,
		context => q|label for link to close ticket tab in help desk main view|
	},
    'view all tickets' => {
		message => q|View All Tickets|,
		lastUpdated => 0,
		context => q|Title for link to 'view all tickets' page.|
	},
    'confirm and close' => {
		message => q|Confirm and Close|,
		lastUpdated => 0,
		context => q|Label for 'confirm mand close' button.|
	},
    'post' => {
		message => q|Post|,
		lastUpdated => 0,
		context => q|Label for comment post buttin.|
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
    'reopen ticket' => {
		message => q|Reopen Ticket|,
		lastUpdated => 0,
		context => q|Label for button that reopens a ticket|
	},
#    'TODO' => {
#		message => q|TODO|,
#		lastUpdated => 0,
#		context => q|TODO|
#	},
};

1;
