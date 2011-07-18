CREATE TABLE HelpDesk (
    assetId VARCHAR(22) BINARY NOT NULL,
    revisionDate BIGINT NOT NULL,
    viewTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000001',
    viewMyTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000002',
    viewAllTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000003',
    searchTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000004',
    manageMetaTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000005',
    editMetaFieldTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000006',
    notificationTemplateId VARCHAR(22) BINARY NOT NULL default 'HELPDESK00000000000007',
    editTicketTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000001',
    viewTicketTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000002',
    viewTicketRelatedFilesTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000003',
    viewTicketUserListTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000004',
    viewTicketCommentsTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000005',
    viewTicketHistoryTemplateId VARCHAR(22) BINARY NOT NULL default 'TICKET0000000000000006',
    richEditIdPost VARCHAR(22) BINARY NOT NULL default 'PBrichedit000000000002',
    approvalWorkflow varchar(22) BINARY NOT NULL default 'pbworkflow000000000003',
    groupToPost VARCHAR(22) BINARY NOT NULL default '3',
    groupToChangeStatus VARCHAR(22) BINARY NOT NULL default '3',
    karmaEnabled TINYINT(4) DEFAULT 0,
    karmaPerPost INTEGER NOT NULL default 0,
    karmaToClose INTEGER NOT NULL default 0,
    defaultKarmaScale INTEGER NOT NULL default 1,
    sortColumn ENUM ('ticketId','title','createdBy','creationDate','assignedTo','ticketStatus','lastReplyDate','karmaRank') DEFAULT 'creationDate',
    sortOrder ENUM('ASC','DESC') DEFAULT 'DESC',
    subscriptionGroup VARCHAR(255) NOT NULL,
    mailServer VARCHAR(255) default NULL,
    mailAccount VARCHAR(255) default NULL,
    mailPassword VARCHAR(255) default NULL,
    mailAddress VARCHAR(255) default NULL,
    mailPrefix VARCHAR(255) default NULL,
    getMail TINYINT(4) NOT NULL default 0,
    getMailInterval INTEGER NOT NULL default 300,
    getMailCronId VARCHAR(22) BINARY default NULL,
    autoSubscribeToTicket TINYINT(4) NOT NULL default 1,
    requireSubscriptionForEmailPosting TINYINT(4) NOT NULL default 1,
    closeTicketsAfter integer not null default 1209600,
    runOnNewTicket varchar(22) BINARY,
    localTicketsOnly TINYINT(4) DEFAULT 0,
    PRIMARY KEY (assetId,revisionDate)
);

CREATE TABLE HelpDesk_metaField (
    fieldId VARCHAR(22) BINARY NOT NULL,
    assetId VARCHAR(22) BINARY NOT NULL,
    label VARCHAR(100) DEFAULT NULL,
    dataType VARCHAR(20) DEFAULT NULL,
    required TINYINT(4) DEFAULT 0,
    searchable TINYINT(4) DEFAULT 0,
    possibleValues TEXT,
    defaultValues TEXT,
    hoverHelp TEXT,
    sequenceNumber INT(5) DEFAULT NULL,
    showInList INT(1),
    PRIMARY KEY  (fieldId)
);

CREATE TABLE Ticket (
    assetId VARCHAR(22) BINARY NOT NULL,
    revisionDate BIGINT NOT NULL,
    ticketId mediumint not null,
    ticketStatus VARCHAR(30) NOT NULL default 'pending',
    assigned tinyint(1) NOT NULL default 0,
    assignedTo VARCHAR(22) BINARY default NULL,
    assignedBy VARCHAR(22) BINARY default NULL,
    dateAssigned BIGINT default NULL,
    storageId VARCHAR(22) BINARY default NULL,
    isPrivate tinyint(1) NOT NULL default 0,
    solutionSummary longtext default NULL,
    comments longtext default NULL,
    averageRating float default 0,
    lastReplyDate BIGINT default NULL,
    lastReplyBy VARCHAR(22) BINARY default NULL,
    resolvedBy VARCHAR(22) BINARY default NULL,
    resolvedDate BIGINT default NULL,
    karma INTEGER NOT NULL default 0,
    karmaScale INTEGER NOT NULL default 1,
    karmaRank FLOAT default NULL,
    subscriptionGroup VARCHAR(255) NOT NULL,
    PRIMARY KEY (assetId,revisionDate)
);

CREATE TABLE Ticket_history (
    historyId VARCHAR(22) BINARY NOT NULL,
    userId VARCHAR(22) BINARY NOT NULL,
    assetId VARCHAR(22) BINARY NOT NULL,
    actionTaken VARCHAR(255) NOT NULL,
    dateStamp BIGINT NOT NULL,
    PRIMARY KEY (historyId)
);

CREATE TABLE Ticket_metaData (
    fieldId VARCHAR(22) BINARY NOT NULL,
    assetId VARCHAR(22) BINARY NOT NULL,
    value MEDIUMTEXT DEFAULT NULL,
    PRIMARY KEY  (fieldId, assetId)
);

CREATE TABLE Ticket_searchIndex (
    assetId VARCHAR(22) BINARY NOT NULL,
    parentId VARCHAR(22) BINARY NOT NULL,
    lineage VARCHAR(255) NOT NULL,
    url VARCHAR(255) NOT NULL,
    ticketId MEDIUMINT NOT NULL,
    creationDate BIGINT NOT NULL, 
    createdBy VARCHAR(22) NOT NULL,
    synopsis text NOT NULL,
    title VARCHAR(255) NOT NULL,
    keywords VARCHAR(255) NOT NULL,
    isPrivate tinyint(1) NOT NULL default 0,
    assignedTo VARCHAR(22) default NULL,
    assignedBy VARCHAR(22) default NULL,
    dateAssigned BIGINT default NULL,
    ticketStatus VARCHAR(30) NOT NULL,
    solutionSummary longtext default NULL,
    averageRating float default 0,
    lastReplyDate BIGINT default NULL,
    lastReplyBy VARCHAR(22) default NULL,
    karmaRank FLOAT default NULL,
    PRIMARY KEY  (assetId)
);

CREATE TABLE Ticket_collabRef (
    origAssetId VARCHAR(22) BINARY NOT NULL,
    mapToAssetId VARCHAR(22) BINARY NOT NULL,
    PRIMARY KEY  (origAssetId)
);

INSERT INTO incrementer (incrementerId,nextValue) VALUES ('ticketId',1);

