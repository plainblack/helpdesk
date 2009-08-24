
/*** The WebGUI Help Desk 
 * Requires: YAHOO, Dom, Event, DataSource, DataTable, Paginator, Container
 *
 */

var DataSource = YAHOO.util.DataSource,
    DataTable  = YAHOO.widget.DataTable,
    Paginator  = YAHOO.widget.Paginator;

if ( typeof WebGUI == "undefined" ) {
    WebGUI  = {};
}

/*** WebGUI HelpDesk Object
 *
 * This object renders the WebGUI HelpDesk datatable
 * 
 * @method WebGUI.HelpDesk.constructor
 * @param configs {Object} object containing configuration necessary for creating the datatable.
 *      datasource        {String}     Required     URL that returns the JSON data structure of data to be displayed.
 *      container         {String}     Required     id of the HTML Element in which to render both the datatable and the pagination
 *      dtContainer       {String}     Required     id of the HTML Element in which to render the datatable
 *      view              {String}     Required     String which is passed to the ticket to properly return uses to the right view [all,my,search].
 *      fields            {ArrayRef}   Required     Array Reference of Objects used by the DataSource to configure and store data to be used by the data table
 *      columns           {ArrayRef}   Required     Array Reference of Objects which define the columns for the datatable to render
 *      p_containers      {ArrayRef}   Required     Array Reference containing the ids of the HTML Elements in which to render pagination.
 *      defaultSort       {Object}     Optional     Custom object which defines which column and direction the paginator should sort by
 *      initRequestString {String}     Optional     Parameters to append to the end of the url when initializing the datatable
 */


WebGUI.HelpDesk = function (configs) {
    // Initialize configs
    this._configs = {};    
    if(configs) {
        this._configs = configs;
    }

    if(!this._configs.initiRequestString) {
        this._configs.initRequestString = ';recordOffset=0';
    }

    ///////////////////////////////////////////////////////////////
    //              Internationalization
    //  this comes first because it is used in other areas...
    ///////////////////////////////////////////////////////////////
    WebGUI.HelpDesk.i18n = new WebGUI.i18n( {
        namespaces : {
            'Asset_HelpDesk' : [
                'confirm and close',
                'reopen ticket',
                'close tab'
            ]
        }
//        onpreload : {
//            fn       : this.initialize,
//            obj      : this,
//            override : true,
//        }
    } );

    ///////////////////////////////////////////////////////////////
    //              Protected Static Methods
    ///////////////////////////////////////////////////////////////
    
    //***********************************************************************************
    //  This method closes the active tab
    //
    //   Parameters:   ( integer ) -- if a ticket id is passed in then remove the tab for that ticket
    //                 ( e, object ) -- cancel the event and close the tab associated with the object
    //                 ( ) -- get the current tab from the tabview object and close it
    //
    WebGUI.HelpDesk.closeTab = function ( e, myTab ) {
        var index;
        if( typeof(e) == "string" || typeof(e) == "number" ) {
            index = e;
            myTab = WebGUI.HelpDesk.Tickets[index].Tab;
        } else {
            if( typeof(e) != "undefined" ) {
                YAHOO.util.Event.preventDefault(e);
            }
            if( typeof(myTab) == "undefined" ) {
                myTab = tabView.get('activeTab');
	    }
            index = parseInt( myTab.get('label') );
        }
        delete WebGUI.HelpDesk.Tickets[index];
        WebGUI.helpDeskTabs.removeTab(myTab);
        if( WebGUI.HelpDesk.lastTab ) {
	   WebGUI.helpDeskTabs.set('activeTab',WebGUI.HelpDesk.lastTab);
        }
    };

    //***********************************************************************************
    // Custom function to handle pagination requests
    WebGUI.HelpDesk.handlePagination = function (state,dt) {
        var sortedBy  = dt.get('sortedBy');
        // Define the new state
        var newState = {
            startIndex: state.recordOffset, 
            sorting: {
                key: sortedBy.key,
                dir: ((sortedBy.dir === DataTable.CLASS_ASC) ? "asc" : "desc")
            },
            pagination : { // Pagination values
                recordOffset: state.recordOffset, // Go to the proper page offset
                rowsPerPage: state.rowsPerPage // Return the proper rows per page
            }
        };

        // Create callback object for the request
        var oCallback = {
            success: dt.onDataReturnSetRows,
            failure: dt.onDataReturnSetRows,
            scope: dt,
            argument: newState // Pass in new state as data payload for callback function to use
        };
        
        // Send the request
        dt.getDataSource().sendRequest(WebGUI.HelpDesk.buildQueryString(newState, dt), oCallback);
    };

    //***********************************************************************************
    //This method is out here so it can be overridden.  The datatable uses this method to sort it's columns
    WebGUI.HelpDesk.sortColumn = function(oColumn,sDir) {
        // Default ascending
        var sDir = "desc";

        // If already sorted, sort in opposite direction
        if(oColumn.key === this.get("sortedBy").key) {
            sDir = (this.get("sortedBy").dir === DataTable.CLASS_ASC) ? "desc" : "asc";
        }

        // Define the new state
        var newState = {
            startIndex: 0,
            sorting: { // Sort values
                key: oColumn.key,
                dir: (sDir === "asc") ? DataTable.CLASS_ASC : DataTable.CLASS_DESC
            },
            pagination : { // Pagination values
                recordOffset: 0, // Default to first page when sorting
                rowsPerPage: this.get("paginator").getRowsPerPage() // Keep current setting
            }
        };

        // Create callback object for the request
        var oCallback = {
            success: this.onDataReturnSetRows,
            failure: this.onDataReturnSetRows,
            scope: this,
            argument: newState // Pass in new state as data payload for callback function to use
        };
        
        // Send the request
        this.getDataSource().sendRequest(WebGUI.HelpDesk.buildQueryString(newState, this), oCallback);
    };

    //***********************************************************************************
    //  This method checks for modifier keys pressed during the mouse click
    function eventModifiers( e ) {
        if( e.event.modifiers ) {
            return e.event.modifiers & (Event.ALT_MASK | Event.CONTROL_MASK
                                | Event.SHIFT_MASK | Event.META_MASK);
        } else {
            return  e.event.altKey | e.event.shiftKey | e.event.ctrlKey;
        }
    }

    //***********************************************************************************
    //  This method is subscribed to by the DataTable and thus becomes a member of the DataTable
    //  class even though it is a member of the HelpDesk Class.  For this reason, a HelpDesk instance
    //  is actually passed to the method as it's second parameter.
    //
    WebGUI.HelpDesk.loadTicket = function ( evt, obj ) {
               // if the user pressed a modifier key we want to default
        if( eventModifiers( evt ) ) { return }
        var target = evt.target;
	if( typeof(WebGUI.HelpDesk.Tickets) == "undefined" ) {
	    WebGUI.HelpDesk.Tickets = new Object();
	}
        
        //let the default action happen if the user clicks the last reply column
        var links = YAHOO.util.Dom.getElementsByClassName ("profile_link","a",target);

        //  the 'loading' 'indicator'
        if( typeof(WebGUI.HelpDesk.ticketLoadingIndicator) == "undefined" ) {
            WebGUI.HelpDesk.ticketLoadingIndicator = new YAHOO.widget.Overlay( "ticketLoadingIndicator", {  
                fixedcenter         : true,
                visible             : false
           } );
            WebGUI.HelpDesk.ticketLoadingIndicator.setBody( "Loading Ticket ..." +
		"<img id='ticketLoadingIndicator' title='loading' src='/extras/wobject/HelpDesk/indicator.gif'/>"
		);
	    WebGUI.HelpDesk.ticketLoadingIndicator.render(document.body);
        }
        WebGUI.HelpDesk.ticketLoadingIndicator.show();
        
        if (links.length == 0) {
            YAHOO.util.Event.stopEvent(evt.event);
        }

        var elCell = this.getTdEl(target);
        if(elCell) {
            var oRecord = this.getRecord(elCell);
            
            if( typeof( WebGUI.HelpDesk.Tickets[oRecord.ticketId] ) != "undefined" ) {
	        WebGUI.helpDeskTabs.set('activeTab',WebGUI.HelpDesk.Tickets[oRecord.ticketId].Tab);
	        WebGUI.HelpDesk.ticketLoadingIndicator.hide();
	    }  else {
		var url     = oRecord.getData('url') + "?func=view;caller=ticketMgr;view=" + obj._configs.view;
	     
		// Create callback object for the request
		var oCallback = {
		    success: function(o) {
			   var response = eval('(' + o.responseText + ')');
			   var myTab;
			   if(response.hasError){
			       var message = "";
			       for(var i = 0; i < response.errors.length; i++) {
				   message += response.errors[i];
			       }
			       alert(message);
			       return;
			   } else if( typeof(WebGUI.HelpDesk.Tickets[response.ticketId]) == "undefined" 
				      || WebGUI.HelpDesk.Tickets[response.ticketId] == null ) {
			       // if there is a tab .. close it,
			       // at least until I can get the JS/HTML re-written to handle multiple tabs
			       //  there should only be one
			       for( var ticketId in WebGUI.HelpDesk.Tickets ) { WebGUI.HelpDesk.closeTab(ticketId) }
			       var myContent = document.createElement("div");
			       myContent.innerHTML = response.ticketText;
			       myTab = new YAHOO.widget.Tab({
				     label: response.ticketId + '<span class="close"><img src="/extras/wobject/HelpDesk/close12_1.gif" alt="X" title="' +
                                            WebGUI.HelpDesk.i18n.get('Asset_HelpDesk','close tab') + '" /></span>',
				     contentEl: myContent
				 });
			       WebGUI.helpDeskTabs.addTab( myTab );
			       YAHOO.util.Event.on(myTab.getElementsByClassName('close')[0], 'click', WebGUI.HelpDesk.closeTab , myTab);
			       WebGUI.HelpDesk.Tickets[response.ticketId] = new Object();
			       WebGUI.HelpDesk.Tickets[response.ticketId].Tab = myTab;
			   } else {
			       myTab = WebGUI.HelpDesk.Tickets[response.ticketId].Tab;
			       myTab.set('content', response.ticketText);
			   }
			   // make sure the script on the ticket has run
			   if( typeof( WebGUI.ticketJScriptRun ) == "undefined" ) {
			       eval( document.getElementById("ticketJScript").innerHTML );
			   }
			   delete WebGUI.ticketJScriptRun;
			   WebGUI.HelpDesk.ticketLoadingIndicator.hide();
			   WebGUI.HelpDesk.lastTab = tabView.get('activeTab');
			   WebGUI.helpDeskTabs.set('activeTab',myTab);
		       },
		    failure: function(o) {
			   WebGUI.HelpDesk.ticketLoadingIndicator.hide();
		       }
		};
		var request = YAHOO.util.Connect.asyncRequest('GET', url, oCallback); 
	    }
        } else {
            alert("Could not get table cell for " + target);
        }
    };


    ///////////////////////////////////////////////////////////////
    //              Public Instance Methods
    ///////////////////////////////////////////////////////////////

    //***********************************************************************************
    this.getDataTable = function() {
        if(!this.helpdesk) {
            return {};
        }
        return this.helpdesk;
    };    

    //***********************************************************************************
    this.getDefaultSort = function() {
        if(this._configs.defaultSort) {
            return this._configs.defaultSort;
        }
        return {
            "key" : "creationDate",
            "dir" : DataTable.CLASS_DESC
        };
    };
    
    //***********************************************************************************
    // Override this method if you want pagination to work differently    
    this.getPaginator = function () {
        return new Paginator({
            containers         : this._configs.p_containers,
            pageLinks          : 5,
            rowsPerPage        : 25,
            rowsPerPageOptions : [25,50,100],
            template           : "<strong>{CurrentPageReport}</strong> {PreviousPageLink} {PageLinks} {NextPageLink} {RowsPerPageDropdown}"
        });
    };

    //***********************************************************************************
    this.initDataTable = function () {
        var datasource  = new DataSource(this._configs.datasource);
        datasource.responseType   = DataSource.TYPE_JSON;
        datasource.responseSchema = {
            resultsList : 'tickets',
            fields      : this._configs.fields,
            metaFields  : { totalRecords: 'totalRecords' }
        };

        // Initialize the data table
        this.helpdesk = new DataTable(
            this._configs.dtContainer,
            this._configs.columns,
            datasource,
            {
                initialRequest         : this._configs.initRequestString,
                paginationEventHandler : WebGUI.HelpDesk.handlePagination,
                paginator              : this.getPaginator(),
                dynamicData            : true, 
                sortedBy               : this.getDefaultSort()
            }
        );
        this.helpdesk.subscribe("rowMouseoverEvent", this.helpdesk.onEventHighlightRow);
        this.helpdesk.subscribe("rowMouseoutEvent", this.helpdesk.onEventUnhighlightRow);
        this.helpdesk.subscribe("cellClickEvent",WebGUI.HelpDesk.loadTicket,this);
        // Override function for custom server-side sorting
        this.helpdesk.sortColumn = WebGUI.HelpDesk.sortColumn;
        this.helpdesk.handleDataReturnPayload = function (oReq, oRes, oPayload ) {
               oPayload.totalRecords = parseInt( oRes.meta.totalRecords );
               return oPayload;
        };
        this.helpdesk.generateRequest = WebGUI.HelpDesk.buildQueryString;
        
        //Work around nested scoping for the callback
        var myHelpdesk = this.helpdesk;
        //ensure no memory leaks with the datatable
    };

};

///////////////////////////////////////////////////////////////
//            Public Static Methods
///////////////////////////////////////////////////////////////

//***********************************************************************************
WebGUI.HelpDesk.formatTitle = function ( elCell, oRecord, oColumn, orderNumber ) {
    elCell.innerHTML = '<a href="' + oRecord.getData('url') + '" id="ticket_' + oRecord.getData( 'ticketId' ) + '" class="ticket_link">'
        + oRecord.getData( 'title' )
        + '</a>'
        ;
};

//***********************************************************************************
WebGUI.HelpDesk.formatLastReply = function ( elCell, oRecord, oColumn, orderNumber ) {
    var lastReplyDate = oRecord.getData('lastReplyDate');
    if(lastReplyDate) {
        elCell.innerHTML = oRecord.getData('lastReplyDate')
            + ' by '+ '<a href="' + getWebguiProperty('pageURL') + "?op=viewProfile;uid=" + oRecord.getData('lastReplyById') + '" class="profile_link">'
            + oRecord.getData( 'lastReplyBy' )
            + '</a>';
    }
    else {
        elCell.innerHTML = "";
    }
};

//***********************************************************************************
WebGUI.HelpDesk.buildQueryString = function ( state, dt ) {
    var query = ";recordOffset=" + state.pagination.recordOffset 
        + ';orderByDirection=' + ((state.sortedBy.dir === DataTable.CLASS_ASC) ? "ASC" : "DESC")
        + ';rowsPerPage=' + state.pagination.rowsPerPage
        + ';orderByColumn=' + state.sortedBy.key
        ;
    return query;
};

