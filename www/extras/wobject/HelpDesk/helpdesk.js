
/*** The WebGUI Help Desk 
 * Requires: YAHOO, Dom, Event, DataSource, DataTable, Paginator, Dispatcher
 *
 */

var DataSource = YAHOO.util.DataSource,
    DataTable  = YAHOO.widget.DataTable,
    Paginator  = YAHOO.widget.Paginator,
    Dispatcher = YAHOO.plugin.Dispatcher;

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
    //              Protected Static Methods
    ///////////////////////////////////////////////////////////////
    
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
    //  This method is subscribed to by the DataTable and thus becomes a member of the DataTable
    //  class even though it is a member of the HelpDesk Class.  For this reason, a HelpDesk instance
    //  is actually passed to the method as it's second parameter.
    //
    WebGUI.HelpDesk.loadTicket = function ( evt, obj ) {
        var target = evt.target;
        
        //let the default action happen if the user clicks the last reply column
        var links = YAHOO.util.Dom.getElementsByClassName ("profile_link","a",target);
        
        if (links.length == 0) {
            YAHOO.util.Event.stopEvent(evt.event);
        }

        var elCell = this.getTdEl(target);
        if(elCell) {
            var oRecord = this.getRecord(elCell);
            
            var url     = oRecord.getData('url') + "?func=view;caller=ticketMgr;view=" + obj._configs.view;
            if(url) {
                // Create callback object for the request
                var oCallback = {
                    success: function(o) {
                        //ensure no memory leaks  
                        var destroyer = Dispatcher.destroyer;
                        if(destroyer != null) {
                            destroyer.subscribe (function(el, config){
                                obj.helpdesk.destroy();
                            });
                        }
                        Dispatcher.process( obj._configs.container, o.responseText );
                    },
                    failure: function(o) {}
                };
                var request = YAHOO.util.Connect.asyncRequest('GET', url, oCallback); 
            }
        }
        else {
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
                generateRequest        : WebGUI.HelpDesk.buildQueryString,
                paginationEventHandler : WebGUI.HelpDesk.handlePagination,
                paginator              : this.getPaginator(),
                sortedBy               : this.getDefaultSort()
            }
        );
        this.helpdesk.subscribe("rowMouseoverEvent", this.helpdesk.onEventHighlightRow);
        this.helpdesk.subscribe("rowMouseoutEvent", this.helpdesk.onEventUnhighlightRow);
        this.helpdesk.subscribe("cellClickEvent",WebGUI.HelpDesk.loadTicket,this);
        // Override function for custom server-side sorting
        this.helpdesk.sortColumn = WebGUI.HelpDesk.sortColumn;
        
        //Work around nested scoping for the callback
        var myHelpdesk = this.helpdesk;
        //ensure no memory leaks with the datatable
        var destroyer = Dispatcher.destroyer;
        if(destroyer != null) {
            destroyer.subscribe (function(el, config){
                myHelpdesk.destroy();
            });
        }   
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
        + ';orderByDirection=' + ((state.sorting.dir === DataTable.CLASS_ASC) ? "ASC" : "DESC")
        + ';rowsPerPage=' + state.pagination.rowsPerPage
        + ';orderByColumn=' + state.sorting.key
        ;
    return query;
};

