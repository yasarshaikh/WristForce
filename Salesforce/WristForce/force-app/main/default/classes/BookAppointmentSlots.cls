public without sharing class BookAppointmentSlots {
    
    @InvocableMethod(
        label = 'Book Appointment Slots'
        description = 'Book Appointment Slot'
    )
    public static List<BookingConfirmationResponse> BookAppointmentSlots(
        List<BookingConfirmationRequest> requests
    ){
        for(BookingConfirmationRequest request: requests){
            return createEventNew(request.ownerID, request.dateTimeToCheck, request.contactIds);
        }
        return null;
    }
    
    public class BookingConfirmationRequest {
        @InvocableVariable(
            required=true
            description='List of contact Ids and time to schedule meeting'
        )
        public DateTime dateTimeToCheck;
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
    
    public static List<BookingConfirmationResponse> createEventNew(String ownerId, DateTime meetingTime, List<String> contactIds) {
        Event meeting = new Event(
            Subject = 'Meeting',
            ownerId = ownerId,
            WhoId = contactIds[0],
            StartDateTime = meetingTime,
            EndDateTime = meetingTime.addHours(1)
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