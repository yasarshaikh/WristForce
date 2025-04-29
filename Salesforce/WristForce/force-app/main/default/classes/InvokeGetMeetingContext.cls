public with sharing class InvokeGetMeetingContext {
    @InvocableMethod(label='Get meeting context information for preparation'
                     description='Returns meeting context including related records and historical data')
    public static List<Response> getMeetingContext(List<Request> requests) {
        Request req = requests[0];
        Response res = new Response();
        
        // Get the Event record and related data
        Event eventRecord = getEventDetails(req.eventId);
        if (eventRecord == null) {
            throw new InvokeMeetingPreparationCoachException('Event not found');
        }
        
        res.eventRecord = eventRecord;
        
        // Get Contact details if available
        if (eventRecord.WhoId != null && String.valueOf(eventRecord.WhoId).startsWith('003')) {
            Contact contactInfo = getContactInfo(eventRecord.WhoId);
            if (contactInfo != null) {
                res.contactInfo = contactInfo;
                
                // Get historical events with this contact
                List<Event> historicalEvents = getHistoricalEvents(eventRecord.WhoId);
                if (!historicalEvents.isEmpty()) {
                    res.historicalEvents = convertToEventInfoList(historicalEvents);
                }

                // Get Contact Account details if available
                if (contactInfo.AccountId != null) {
                    Account accountInfo = getAccountDetails(contactInfo.AccountId);
                    if (accountInfo != null) {
                        res.contactAccount = accountInfo;
                        
                        // Get related opportunities
                        OpportunityInfo oppInfo = getAccountOpportunities(contactInfo.AccountId);
                        if (oppInfo != null && (oppInfo.totalOpportunities > 0 || !oppInfo.recentOpportunities.isEmpty())) {
                            res.contactOpportunities = oppInfo;
                        }
                    }
                }
            }
        }
        
        // Get related object info (What)
        if (eventRecord.WhatId != null) {
            RelatedObjectInfo relatedInfo = getRelatedObjectInfo(eventRecord.WhatId);
            if (relatedInfo != null) {
                res.relatedObjectInfo = relatedInfo;
            }
        }
        
        return new List<Response>{ res };
    }
    
    private static List<InvokeGetUserEvents.EventInfo> convertToEventInfoList(List<Event> events) {
        if (events == null || events.isEmpty()) {
            return new List<InvokeGetUserEvents.EventInfo>();
        }
        
        List<InvokeGetUserEvents.EventInfo> eventInfos = new List<InvokeGetUserEvents.EventInfo>();
        for(Event evt : events) {
            InvokeGetUserEvents.EventInfo info = new InvokeGetUserEvents.EventInfo();
            info.eventId = evt.Id;
            info.subject = String.isBlank(evt.Subject) ? '(No Subject)' : evt.Subject;
            info.startDateTime = evt.StartDateTime;
            info.endDateTime = evt.EndDateTime;
            info.description = evt.Description;
            info.location = evt.Location;
            info.contactId = evt.WhoId;
            info.contactName = evt.Who?.Name;
            eventInfos.add(info);
        }
        return eventInfos;
    }
    
    private static Event getEventDetails(Id eventId) {
        List<Event> events = [
            SELECT Id, Subject, Description, StartDateTime, EndDateTime, 
                   Location, WhoId, WhatId, Type, ShowAs
            FROM Event 
            WHERE Id = :eventId
            LIMIT 1
        ];
        return !events.isEmpty() ? events[0] : null;
    }
    
    private static Contact getContactInfo(Id contactId) {
        List<Contact> contacts = [
            SELECT Id, Name, Title,
                   Email, Phone, Department, AccountId
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        return !contacts.isEmpty() ? contacts[0] : null;
    }

    private static Account getAccountDetails(Id accountId) {
        List<Account> accounts = [
            SELECT Id, Name, Industry, Type, Website,
                   BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry,
                   Phone, AnnualRevenue
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        return !accounts.isEmpty() ? accounts[0] : null;
    }
    
    private static List<Event> getHistoricalEvents(Id whoId) {
        DateTime startDate = System.today().addMonths(-6);
        DateTime endDate = System.today();
        
        return [
            SELECT Id, Subject, StartDateTime, EndDateTime, 
                   Location, WhoId, Who.Name, Description
            FROM Event 
            WHERE WhoId = :whoId
            AND StartDateTime >= :startDate
            AND EndDateTime <= :endDate
            ORDER BY StartDateTime DESC
            LIMIT 3
        ];
    }

    private static OpportunityInfo getAccountOpportunities(Id accountId) {
        OpportunityInfo info = new OpportunityInfo();
        
        info.totalOpportunities = [
            SELECT COUNT()
            FROM Opportunity
            WHERE AccountId = :accountId
        ];
        
        info.recentOpportunities = [
            SELECT Id, Name, Amount, StageName, CloseDate
            FROM Opportunity
            WHERE AccountId = :accountId
            ORDER BY CloseDate DESC
            LIMIT 3
        ];
        
        return info;
    }
    
    private static RelatedObjectInfo getRelatedObjectInfo(Id whatId) {
        try {
            String objectType = whatId.getSObjectType().getDescribe().getName();
            RelatedObjectInfo info = new RelatedObjectInfo();
            info.objectType = objectType;
            
            String query = 'SELECT Id, Name';
            
            switch on objectType {
                when 'Account' {
                    query += ', Industry, Type, Website FROM Account';
                }
                when 'Opportunity' {
                    query += ', Amount, StageName, CloseDate FROM Opportunity';
                }
                when else {
                    query += ' FROM ' + objectType;
                }
            }
            
            query += ' WHERE Id = :whatId LIMIT 1';
            
            List<SObject> records = Database.query(query);
            if (records.isEmpty()) {
                return null;
            }
            
            SObject record = records[0];
            info.recordId = record.Id;
            info.name = (String)record.get('Name');
            
            if (objectType == 'Account') {
                info.additionalInfo = String.format('Industry: {0}, Type: {1}, Website: {2}', 
                    new List<Object>{
                        record.get('Industry'),
                        record.get('Type'),
                        record.get('Website')
                    }
                );
            } else if (objectType == 'Opportunity') {
                info.additionalInfo = String.format('Amount: {0}, Stage: {1}, Close Date: {2}', 
                    new List<Object>{
                        record.get('Amount'),
                        record.get('StageName'),
                        record.get('CloseDate')
                    }
                );
            }
            
            return info;
        } catch (Exception e) {
            return null;
        }
    }
    
    public class Request {
        @InvocableVariable(Label='Event ID' Description='ID of the Event to analyze' Required=true)
        public Id eventId;
    }
    
    public class Response {
        @InvocableVariable(Label='Event Record' Description='Details of the specified Event')
        public Event eventRecord;
        
        @InvocableVariable(Label='Contact Information' Description='Related Contact details including Account information')
        public Contact contactInfo;
        
        @InvocableVariable(Label='Historical Events' Description='Previous Events with the same Contact')
        public List<InvokeGetUserEvents.EventInfo> historicalEvents;
        
        @InvocableVariable(Label='Related Object Information' Description='Details of the related object (What)')
        public RelatedObjectInfo relatedObjectInfo;

        @InvocableVariable(Label='Contact Account' Description='Detailed Account information for the Contact')
        public Account contactAccount;

        @InvocableVariable(Label='Contact Account Opportunities' Description='Recent Opportunities related to the Contact Account')
        public OpportunityInfo contactOpportunities;
    }
    
    public class RelatedObjectInfo {
        @InvocableVariable(Label='Object Type' Description='Type of the related object')
        public String objectType;
        
        @InvocableVariable(Label='Record ID' Description='ID of the related record')
        public Id recordId;
        
        @InvocableVariable(Label='Name' Description='Name of the related record')
        public String name;
        
        @InvocableVariable(Label='Additional Information' Description='Formatted string with object-specific details')
        public String additionalInfo;
    }

    public class OpportunityInfo {
        @InvocableVariable(Label='Total Opportunities' Description='Total number of opportunities for the account')
        public Integer totalOpportunities;

        @InvocableVariable(Label='Recent Opportunities' Description='List of 5 most recent opportunities')
        public List<Opportunity> recentOpportunities;
    }
    
    public class InvokeMeetingPreparationCoachException extends Exception {}
}