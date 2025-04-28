public with sharing class InvokeGetUserEvents {
    @InvocableMethod(Label='Get Events/Meetings scheduled between specified date-times for the User'
                     Description='Returns Events/Meetings scheduled between specified date-times for the User')
    public static List<Response> getUserEvents(List<Request> requests) {
        Request req = requests[0];
        Datetime startDateTime = getStartDateTime(req);
        Datetime endDateTime = getEndDateTime(req);
        Integer listOffset = getListOffset(req);
        Integer listLimit = getListLimit(req);
        List<Id> contactIds = getContactIds(req);
        
        Response res = new Response();
        res.totalNumber = getTotalEventsCount(startDateTime, endDateTime, contactIds);
        List<Event> events = getEventsList(startDateTime, endDateTime, listOffset, listLimit, contactIds);
        res.records = convertToEventInfo(events);
        res.eventsText = formatEventsText(events);
        
        return new List<Response>{ res };
    }
    
    private static Datetime getStartDateTime(Request req) {
        return req.startDateTime ?? Datetime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0));
    }
    
    private static Datetime getEndDateTime(Request req) {
        return req.endDateTime ?? Datetime.newInstance(System.today(), Time.newInstance(23, 59, 59, 0));
    }
    
    private static Integer getListOffset(Request req) {
        return req.listOffset != null ? Math.max(req.listOffset, 0) : 0;
    }
    
    private static Integer getListLimit(Request req) {
        if (req.listLimit == null || req.listLimit <= 0) {
            return 10;
        }
        else if (req.listLimit >= 50) {
            return 50;
        } else {
            return req.listLimit;
        }
    }
    
    private static List<Id> getContactIds(Request req) {
        if (req.contactIds == null || req.contactIds.isEmpty()) return new List<Id>();
        return req.contactIds;
    }
    
    private static String buildBaseQueryConditions(Datetime startDateTime, Datetime endDateTime, List<Id> contactIds) {
        String conditions = 'WHERE OwnerId = :currentUserId ' +
            'AND StartDateTime >= :startDateTime ' +
            'AND EndDateTime <= :endDateTime ' +
            'AND IsArchived = FALSE ';
            
        if (!contactIds.isEmpty()) {
            conditions += 'AND WhoId IN :contactIds ';
        }
        
        return conditions;
    }
    
    private static Integer getTotalEventsCount(Datetime startDateTime, Datetime endDateTime, List<Id> contactIds) {
        Id currentUserId = UserInfo.getUserId();
        String query = 'SELECT COUNT() FROM Event ' + 
            buildBaseQueryConditions(startDateTime, endDateTime, contactIds);
        
        return Database.countQuery(query);
    }
    
    private static List<Event> getEventsList(Datetime startDateTime, Datetime endDateTime, Integer listOffset, Integer listLimit, List<Id> contactIds) {
        Id currentUserId = UserInfo.getUserId();
        String query = 'SELECT Id, Subject, StartDateTime, EndDateTime, Who.Name, WhoId, Description, Location ' +
            'FROM Event ' +
            buildBaseQueryConditions(startDateTime, endDateTime, contactIds) +
            'ORDER BY StartDateTime ASC LIMIT :listLimit OFFSET :listOffset';
        
        return Database.query(query);
    }

    private static List<EventInfo> convertToEventInfo(List<Event> events) {
        List<EventInfo> eventInfos = new List<EventInfo>();
        for(Event evt : events) {
            EventInfo info = new EventInfo();
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
    
    private static List<String> formatEventsText(List<Event> events) {
        List<String> formattedEvents = new List<String>();
        for(Event eventRec : events) {
            String subject = String.isBlank(eventRec.Subject) ? '(No Subject)' : eventRec.Subject;
            String participant = eventRec.Who != null ? eventRec.Who.Name : 'No related contact assigned';
            
            formattedEvents.add(
                String.format(
                    '{0} - {1}: {2} (Contact: {3})', 
                    new List<Object>{ 
                        eventRec.StartDateTime,
                        eventRec.EndDateTime,
                        subject,
                        participant
                    }
                )
            );
        }
        return formattedEvents;
    }
    
    public class Request {
        @InvocableVariable(Label='Start Date-Time' Description='Set Today date with 00:00 time by default.' Required=true)
        public Datetime startDateTime;
        
        @InvocableVariable(Label='End Date-Time' Description='Set Today date with 23:59 time by default.' Required=true)
        public Datetime endDateTime;
        
        @InvocableVariable(Label='List Offset' Description='For pagination - how many records to skip from the beginning, 0 by default.' Required=false)
        public Integer listOffset;
        
        @InvocableVariable(Label='List Limit' Description='For pagination - max number of Events to show, must be positive integer <= 50, 10 by default. To show more than 50 records - invoke this method several times with corresponding pagination params.' Required=false)
        public Integer listLimit;
        
        @InvocableVariable(Label='Contact IDs' Description='To filter events by related Contact ("Related To" field on Event page). If set - only Events that are related to any Contact list will be shown.' Required=false)
        public List<String> contactIds;
    }
    
    public class Response {
        @InvocableVariable(Label='Events List' Description='List of Event info objects')
        public List<EventInfo> records;
        
        @InvocableVariable(Label='Events Text' Description='List of formatted event short summaries')
        public List<String> eventsText;
        
        @InvocableVariable(Label='Total Number' Description='Total number of events matching the filter criteria')
        public Integer totalNumber;
    }

    public class EventInfo {
        @AuraEnabled public Id eventId;
        @AuraEnabled public String subject;
        @AuraEnabled public Datetime startDateTime;
        @AuraEnabled public Datetime endDateTime;
        @AuraEnabled public String description;
        @AuraEnabled public String location;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
    }
}