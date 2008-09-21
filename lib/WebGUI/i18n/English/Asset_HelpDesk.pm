package WebGUI::i18n::English::Asset_HelpDesk;
use strict;

our $I18N = {
	'assetName' => {
        message => q|Help Desk|,
        context => q|label for Help Desk, getName|,
        lastUpdated => 1128640132,
    },

    'hoverHelp_possibleValues' => {
        message => q{<p>This area should only be used in with the following form fields:
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
        message => q|<p>Default value you wish to display in the field.  For fields that can have multiple default values, list default values as mulitple line items</p>|,
        lastUpdated => 1122316558,
    },

    'subscribe_link' => {
        message => q{subscribe},
        lastUpdated => 1122316558,
    },

    'unsubscribe_link' => {
        message => q{unsubscribe},
        lastUpdated => 1122316558,
    },
};

1;
