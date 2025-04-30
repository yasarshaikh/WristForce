public without sharing class BookAppointmentSlots {
    
    @InvocableMethod(
        label = 'Book Appointment Slots'
        description = 'Book Appointment Slot'
    )
    public static List<BookingConfirmationResponse> BookAppointmentSlots(
        List<BookingConfirmationRequest> requests
    ){
        for(BookingConfirmationRequest request: requests){
            return createEventNew(request.subject, request.accountName, request.ownerID, request.dateTimeToCheck, request.contactIds);
        }
        return null;
    }
    
    public class BookingConfirmationRequest {
        @InvocableVariable(
            required=true
            description='List of contact Ids and time to schedule meeting'
        )
        public String dateTimeToCheck;
        @InvocableVariable(
            required=true
            description='Contact or Lead Name that we want to Book appointment with.'
        )
        public List<String> contactIds;
        @InvocableVariable(
            required=true
            description='ownerID'
        )
        public String ownerId;
        @InvocableVariable(
            required=true
            description='accountName'
        )
        public String accountName;
         @InvocableVariable(
            required=true
            description='subject'
        )
        public String subject;
    }
    
    public class BookingConfirmationResponse {
        @InvocableVariable(
            description='Booking success'
        )
        public Event meeting;
        public BookingConfirmationResponse(Event meeting){
            this.meeting = meeting;
        }
    }
    
    public static List<BookingConfirmationResponse> createEventNew(String Subject, String AccountName, String ownerId, String meetingTime, List<String> contactIds) {
        DateTime meetingDateTime = Datetime.valueOf(meetingTime);
        string allstring = 'FIND\'  ' +string.join(contactIds,' OR ')+'\' RETURNING Contact, Lead';
        contactIds = new List<String>();
        List<List<sObject>> searchList = Search.query(allstring);
        for (List<SObject> lst : searchList) {
            for (SObject sobj : lst) {
                contactIds.add(String.valueOf(sobj.get('id')));
            }
		}
        allstring = 'FIND\'  ' +ownerId+'\' RETURNING User';
        searchList = Search.query(allstring);
        for (List<SObject> lst : searchList) {
            for (SObject sobj : lst) {
                ownerID = String.valueOf(sobj.get('id'));
            }
		}
        allstring = 'FIND\'  ' +AccountName+'\' RETURNING Account';
        searchList = Search.query(allstring);
        for (List<SObject> lst : searchList) {
            for (SObject sobj : lst) {
                AccountName = String.valueOf(sobj.get('id'));
            }
		}
        Event meeting = new Event(
            WhatId = AccountName,
            Subject = Subject,
            ownerId = userInfo.getUserId(),
            WhoId = contactIds[0],
            StartDateTime = meetingDateTime,
            EndDateTime = meetingDateTime.addHours(1)
        );
        insert meeting;
        
        List<EventRelation> invitations = new List<EventRelation>();
        for(Id contactId : contactIds){
            invitations.add(new EventRelation(
                EventId = meeting.Id,
                RelationId = contactId,
                IsInvitee = true
            ));
        }
        //insert invitations;
        List<BookingConfirmationResponse> responseList = new List<BookingConfirmationResponse>();
        responseList.add(new BookingConfirmationResponse(meeting));
        return responseList;
    }
    
}