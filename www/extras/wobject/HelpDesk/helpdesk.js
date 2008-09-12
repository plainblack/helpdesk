
/*** The WebGUI Help Desk 
 * Requires: YAHOO, Dom, Event
 *
 */

if ( typeof WebGUI == "undefined" ) {
    WebGUI  = {};
}
if ( typeof WebGUI.HelpDesk == "undefined" ) {
    WebGUI.HelpDesk = {};
}

// The extras folder
WebGUI.HelpDesk.extrasUrl   = '/extras/';


/*---------------------------------------------------------------------------
    WebGUI.HelpDesk.formatAssetIdCheckbox ( )
    Format the checkbox for the asset ID.
*/
WebGUI.HelpDesk.formatAssetIdCheckbox 
= function ( elCell, oRecord, oColumn, orderNumber ) {
    elCell.innerHTML = '<input type="checkbox" name="assetId" value="' + oRecord.getData("assetId") + '"'
        + 'onchange="WebGUI.AssetManager.toggleHighlightForRow( this )" />';
};

/*---------------------------------------------------------------------------
    WebGUI.HelpDesk.formatRevisionDate ( )
    Format the asset class name
*/
WebGUI.HelpDesk.formatRevisionDate
= function ( elCell, oRecord, oColumn, orderNumber ) {
    var revisionDate    = new Date( oRecord.getData( "revisionDate" ) * 1000 );
    var minutes = revisionDate.getMinutes();
    if (minutes < 10)
        minutes = "0" + minutes;
    elCell.innerHTML    = revisionDate.getFullYear() + '-' + ( revisionDate.getMonth() + 1 )
                        + '-' + revisionDate.getDate() + ' ' + ( revisionDate.getHours() )
                        + ':' + minutes
                        ;
};

/*---------------------------------------------------------------------------
    WebGUI.HelpDesk.formatTitle ( )
    Format the link for the title
*/
WebGUI.AssetManager.formatTitle
= function ( elCell, oRecord, oColumn, orderNumber ) {
    elCell.innerHTML = '<span class="hasChildren">' 
        + ( oRecord.getData( 'childCount' ) > 0 ? "+" : "&nbsp;" )
        + '</span> <a href="' + oRecord.getData( 'url' ) + '?op=assetManager;method=manage">'
        + oRecord.getData( 'title' )
        + '</a>'
        ;
};

/*---------------------------------------------------------------------------
    WebGUI.HelpDesk.initManager ( )
    Initialize the www_manage page
*/
WebGUI.HelpDesk.init
= function (o) {
    var helpDeskPaginator = new YAHOO.widget.Paginator({
        containers         : ['paging_top','paging_bottom'],
        pageLinks          : 5,
        rowsPerPage        : 10,
        rowsPerPageOptions : [10,25,50,100],
        template           : "<strong>{CurrentPageReport}</strong> {PreviousPageLink} {PageLinks} {NextPageLink} {RowsPerPageDropdown}"
    });

    var buildQueryString = function ( state, dt ) {
        var query = ";recordOffset=" + state.pagination.recordOffset 
            + ';orderByDirection=' + ((state.sorting.dir === YAHOO.widget.DataTable.CLASS_ASC) ? "ASC" : "DESC")
            + ';rowsPerPage=' + state.pagination.rowsPerPage
            + ';orderByColumn=' + state.sorting.key
            ;
        return query;
    };

    // Custom function to handle pagination requests
    var handlePagination = function (state,dt) {
        var sortedBy  = dt.get('sortedBy');
        // Define the new state
        var newState = {
            startIndex: state.recordOffset, 
            sorting: {
                key: sortedBy.key,
                dir: ((sortedBy.dir === YAHOO.widget.DataTable.CLASS_ASC) ? "asc" : "desc")
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
        dt.getDataSource().sendRequest(buildQueryString(newState, dt), oCallback);
    };

    // Initialize the data table
    WebGUI.HelpDesk.DataTable
        = new YAHOO.widget.DataTable('dt',
            WebGUI.HelpDesk.ColumnDefs,
            WebGUI.HelpDesk.DataSource,
            {
                initialRequest         : ';recordOffset=0',
                generateRequest        : buildQueryString,
                paginationEventHandler : handlePagination,
                paginator              : helpDeskPaginator,
                sortedBy               : WebGUI.HelpDesk.DefaultSortedBy
            }
    );
    WebGUI.HelpDesk.DataTable.subscribe("rowMouseoverEvent", WebGUI.HelpDesk.DataTable.onEventHighlightRow);
    WebGUI.HelpDesk.DataTable.subscribe("rowMouseoutEvent", WebGUI.HelpDesk.DataTable.onEventUnhighlightRow);
        //myTable.subscribe("rowClickEvent",openTicket);


    // Override function for custom server-side sorting
    WebGUI.HelpDesk.DataTable.sortColumn = function(oColumn) {
        // Default ascending
        var sDir = "desc";

        // If already sorted, sort in opposite direction
        if(oColumn.key === this.get("sortedBy").key) {
            sDir = (this.get("sortedBy").dir === YAHOO.widget.DataTable.CLASS_ASC) ? "desc" : "asc";
        }

        // Define the new state
        var newState = {
            startIndex: 0,
            sorting: { // Sort values
                key: oColumn.key,
                dir: (sDir === "asc") ? YAHOO.widget.DataTable.CLASS_ASC : YAHOO.widget.DataTable.CLASS_DESC
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
        this.getDataSource().sendRequest(buildQueryString(newState, this), oCallback);
    };

};

