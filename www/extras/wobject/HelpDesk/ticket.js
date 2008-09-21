
/*** The WebGUI Ticket
 * Requires: YAHOO, Dom, Event, DataSource, DataTable, Paginator, Dispatcher
 *
 */

if ( typeof WebGUI == "undefined" ) {
    WebGUI  = {};
}

if ( typeof WebGUI.Ticket == "undefined" ) {
    WebGUI.Ticket  = {};
}

//***********************************************************************************
WebGUI.Ticket.findFirstFormElement = function( node ) {
    var children    = YAHOO.util.Dom.getChildren(node);
    var hasChildren = children.length;
    if(hasChildren == 0) return null;
    //Check to see if the fields are the right types
    for( var i = 0; i < children.length; i++) {
        if(children[i].tagName == "INPUT" || children[i].tagName == "SELECT") return children[i];
        var inputNode = WebGUI.Ticket.findFirstFormElement(children[i]);
        if(inputNode != null) return inputNode;
    }
    //Nothing found
    return null;
}

//***********************************************************************************
WebGUI.Ticket.findUsers = function(o) {
    var oCallback = {
        success: function(o) {
            YAHOO.util.Dom.setStyle('userSearchIndicator','display','none');
            var userList = YAHOO.util.Dom.get('userList');
            YAHOO.plugin.Dispatcher.process( "userList", o.responseText );
        },
        failure: function(o) {}
    };            
    YAHOO.util.Dom.setStyle('userSearchIndicator', 'display', '');
    YAHOO.util.Connect.setForm("userSearchForm");
    YAHOO.util.Connect.asyncRequest('POST', WebGUI.Ticket.userSearchUrl, oCallback);
}

//***********************************************************************************
WebGUI.Ticket.loadField = function(o, obj) {
    var button     = YAHOO.util.Event.getTarget(o);
    
    var fieldId    = obj.fieldId;    
    var url        = WebGUI.Ticket.getFormFieldUrl + ";fieldId=" + fieldId;    

    var oCallback = {
        success: function(o) {
            //Put the form field into the node
            var valueField = YAHOO.util.Dom.get("field_id_"+fieldId); 
            valueField.innerHTML = o.responseText;
            //Remove the current listener from the link
            var href             = YAHOO.util.Dom.getAncestorByTagName(button,"A");            
            YAHOO.util.Event.removeListener(href,'click',WebGUI.Ticket.loadField);
            WebGUI.Ticket.removeAllChildren(href);
            //Add the save button to the node
            var saveButton       = document.createElement("INPUT");
            saveButton.setAttribute("type","button");
            saveButton.setAttribute("value","save");
            href.appendChild(saveButton);
            //Add a new listener to the link
            YAHOO.util.Event.addListener(saveButton,'click',WebGUI.Ticket.saveFieldValue,{
                fieldId    : obj.fieldId,
                buttonSrc  : button.src
            });
            //Get the form field added to the link node
            var formField = WebGUI.Ticket.findFirstFormElement(valueField);
            //Set focus on the form field
            formField.focus();
        },
        failure: function(o) {}
    };
    
    YAHOO.util.Connect.asyncRequest('GET', url, oCallback);
}

//***********************************************************************************
WebGUI.Ticket.postComment = function (o, obj) {

    var oCallback = {
        success: function(o) {
            var response = eval('(' + o.responseText + ')');
            if(response.hasError){
                alert(WebGUI.Ticket.processErrors(response.errors));
            }
            else {
                YAHOO.util.Connect.asyncRequest('GET', WebGUI.Ticket.getCommentsUrl, {
                    success: function (o) {
                        YAHOO.util.Dom.get("comments").innerHTML = o.responseText;
                        YAHOO.util.Dom.get("commentsForm").reset();
                        var averageRatingImg   = YAHOO.util.Dom.get("averageRatingImg");
                        averageRatingImg.src   = response.averageRatingImage;
                        averageRatingImg.title = response.averageRating;
                        averageRatingImg.alt   = response.averageRating;
                        YAHOO.util.Dom.get("field_id_ticketStatus").innerHTML = response.ticketStatus;
                        WebGUI.Ticket.rebuildHistory();
                        //Easter Egg for plainblack.com
                        WebGUI.Ticket.updateKarmaMessage(response.karmaLeft);
                        window.solutionDialog.hide();
                    },
                    failure: function(o) {}
                });
            }   
        },
        failure: function(o) {}
    };
    YAHOO.util.Connect.setForm(obj.form);
    YAHOO.util.Connect.asyncRequest('POST', WebGUI.Ticket.postCommentUrl, oCallback);
};

//***********************************************************************************
WebGUI.Ticket.postKeywords = function (o , obj) {
    var oCallback = {
        success: function(o) {
            var response = eval('(' + o.responseText + ')');
            if(response.hasError){
                alert(WebGUI.Ticket.processErrors(response.errors));
            }
            else {
                var keywords       = YAHOO.util.Dom.get("keywordDiv");
                var keywordsStr    = "";
                for (i = 0; i < response.keywords.length; i++) {
                    if(i > 0) keywordsStr += obj.seperator;
                    keywordsStr += response.keywords[i];
                }
                keywords.innerHTML = keywordsStr;
            }
        }
    };
    YAHOO.util.Connect.setForm("keywordsForm");
    YAHOO.util.Connect.asyncRequest('POST', WebGUI.Ticket.postKeywordsUrl, oCallback);
}

//***********************************************************************************
WebGUI.Ticket.processErrors = function ( errors ) {
    if(typeof errors != 'object') errors = [];
    var message = "";
    for (var i = 0; i < errors.length; i++) {
        if(i > 0) message += "\n";
        message += errors[i];
    }
    return message;
}


//***********************************************************************************
WebGUI.Ticket.rebuildHistory = function () {
    var oCallback = {
        success: function(o) {
            var ticketHistory = YAHOO.util.Dom.get("ticketHistory");
            ticketHistory.innerHTML = o.responseText;
        },
        failure: function(o) {}
    };
    YAHOO.util.Connect.asyncRequest('GET', WebGUI.Ticket.historyUrl, oCallback);
};

//***********************************************************************************
WebGUI.Ticket.removeAllChildren = function( node ) {
    var children = YAHOO.util.Dom.getChildren(node);
    for(var i= 0; i < children.length; i++) {
        node.removeChild(children[i]);
    }
}

//***********************************************************************************
WebGUI.Ticket.saveFieldValue = function(o, obj) {
    var button     = YAHOO.util.Event.getTarget(o);
    
    var fieldId    = obj.fieldId;
    var valueField = YAHOO.util.Dom.get("field_id_"+fieldId);
    var formField  = WebGUI.Ticket.findFirstFormElement(valueField);
    var fieldValue = WebGUI.Form.getFormValue(formField);
    var url        = WebGUI.Ticket.saveUrl + ";fieldId=" + fieldId + ";value=" + encodeURIComponent(fieldValue);    
    
    var oCallback = {
        success: function(o) {
            var response = eval('(' + o.responseText + ')');
            if(response.hasError){
                alert(WebGUI.Ticket.processErrors(response.errors));
            }
            else {
                valueField.innerHTML = response.value;        
                var href             = YAHOO.util.Dom.getAncestorByTagName(button,"A");
                YAHOO.util.Event.removeListener(href,'click',WebGUI.Ticket.saveFieldValue);
                WebGUI.Ticket.removeAllChildren(href);
                var editButton = document.createElement("IMG");
                editButton.setAttribute("src",obj.buttonSrc);
                editButton.setAttribute("title","Change");
                editButton.setAttribute("alt","Change");
                YAHOO.util.Dom.setStyle(editButton,"border","0");
                YAHOO.util.Dom.setStyle(editButton,"vertical-align","middle");
                href.appendChild(editButton);
                YAHOO.util.Event.addListener(href,'click',WebGUI.Ticket.loadField,{ fieldId : obj.fieldId });
                //Rebuild the history
                WebGUI.Ticket.rebuildHistory();
                //Pop up the comment box when you change a status
                if(fieldId == "ticketStatus") {
                    var solutionDialog = YAHOO.util.Dom.get("solution_formId");
                    solutionDialog.value = response.value + " by " + response.username;
                    window.solutionDialog.show();
                    //Easter Egg for plainblack.com
                    WebGUI.Ticket.updateKarmaMessage(response.karmaLeft);
                }
                else if(fieldId == "karmaScale") {
                    YAHOO.util.Dom.get("solution_formId").value = "Difficulty updated by " + response.username;
                    YAHOO.util.Dom.get("karmaRank").innerHTML = response.karmaRank;
                    window.solutionDialog.show();
                }
            }
        },
        failure: function(o) {}
    };
    
    YAHOO.util.Connect.asyncRequest('GET', url, oCallback);
}

//***********************************************************************************
//Sets who the ticket is assigned to
WebGUI.Ticket.setAssignment = function ( o, obj ) {
    var target     = YAHOO.util.Event.getTarget(o);
    var id         = target.id;
    var parts      = id.split("~");
    
    var assignedTo = "unassigned";
    if(parts.length > 1) {
        assignedTo  = parts[1];
    }

    var setAssignmentUrl   = WebGUI.Ticket.setAssignmentUrl + ";assignedTo=" + assignedTo;
    var oCallback = {
        success: function(o) {
            var response = eval('(' + o.responseText + ')');
            if(response.hasError){
                alert(WebGUI.Ticket.processErrors(response.errors));
            }
            else {
                YAHOO.util.Dom.get("assignedTo").innerHTML   = response.assignedTo;
                YAHOO.util.Dom.get("dateAssigned").innerHTML = response.dateAssigned;
                YAHOO.util.Dom.get("assignedBy").innerHTML   = response.assignedBy;
                WebGUI.Ticket.rebuildHistory();
                window.assignDialog.hide();
            }
        }
    };
    YAHOO.util.Connect.asyncRequest('GET', setAssignmentUrl, oCallback);
};

//***********************************************************************************
WebGUI.Ticket.showAssignDialog = function (o) {
    var ticketStatus = YAHOO.util.Dom.get("field_id_ticketStatus");
    if(ticketStatus.innerHTML == "Closed") {
        alert("You cannot assign a closed ticket.  Please reopen the ticket and try again");
    }
    else {
        window.assignDialog.show();
    }
}

//***********************************************************************************
//Function used to toggle the solution summary
WebGUI.Ticket.toggleSolutionRow = function() {
    var ticketStatus = YAHOO.util.Dom.get("field_id_ticketStatus").innerHTML;
    if(ticketStatus.toLowerCase() == "closed") {
        YAHOO.util.Dom.setStyle('solutionRow', 'display', '');
    }
    else {
        YAHOO.util.Dom.setStyle('solutionRow', 'display', 'none');
    }
};

//***********************************************************************************
WebGUI.Ticket.transferKarma = function (o) {
    var karma = YAHOO.util.Dom.get("karmaAmount_formId").value;
    var url   = WebGUI.Ticket.transferKarmaUrl + ";karma=" + karma
    var oCallback = {
        success: function(o) {
            var response = eval('(' + o.responseText + ')');
            if(response.hasError){
                alert(WebGUI.Ticket.processErrors(response.errors));
            }
            else {
                YAHOO.util.Dom.get("karma").innerHTML     = response.karma;
                YAHOO.util.Dom.get("karmaRank").innerHTML = response.karmaRank;
                //Easter Egg for plainblack.com
                WebGUI.Ticket.updateKarmaMessage(response.karmaLeft);
                //Rebuild the history
                WebGUI.Ticket.rebuildHistory();
                YAHOO.util.Dom.get("karmaAmount_formId").value = "";
            }
        }
    };
    YAHOO.util.Connect.asyncRequest('GET',url, oCallback);
}

//***********************************************************************************
WebGUI.Ticket.updateKarmaMessage = function ( karma ) {
    if(karma == null) return;
    var links = document.getElementsByTagName('A');
    for(i = 0; i < links.length; i++) {
        var href = links[i].href;
        if(href.indexOf(WebGUI.Ticket.karmaUrl) > -1) {
            links[i].innerHTML = "You have "+ karma + " karma to spend.";
            return;
        }
    }
}

//***********************************************************************************
//Function used to process uploads
WebGUI.Ticket.uploadHandler = function (o) {
    var oCallback = {
        upload: function(o) {
            YAHOO.util.Dom.setStyle('indicator','visibility','hidden');
            var response = eval('(' + o.responseText + ')');
            if(response.hasError){
                alert(WebGUI.Ticket.processErrors(response.errors));
            }
            else {
                YAHOO.util.Connect.asyncRequest('GET', WebGUI.Ticket.listFileUrl, {
                    success: function (o) {
                        YAHOO.util.Dom.get('relatedFiles').innerHTML = o.responseText;
                        YAHOO.util.Dom.get('attachment_id').value    = '';
                    },
                    failure: function(o) {}
                });
            }   
        }
    };
    YAHOO.util.Dom.setStyle('indicator', 'visibility', 'visible');
    //the second argument of setForm is crucial which tells Connection Manager this is an file upload form
    YAHOO.util.Connect.setForm('fileUploadForm', true);
    YAHOO.util.Connect.asyncRequest('POST', WebGUI.Ticket.postFileUrl, oCallback);
};
