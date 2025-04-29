public without sharing class CheckAppointmentSlots {
    
    @InvocableMethod(
        label = 'Check Appointment Slots'
        description = 'Used to check if an appointment slot is available for the given time'
    )
    public static List<AppointmentResponse> getAppointmentSlots(
        List<AppointmentRequest> requests
    ){
        for(AppointmentRequest request: requests){
            return checkAppointmentAvailability(request.dateTimeToCheck, request.contactIds);
        }
        return null;
    }
    
    public static List<AppointmentResponse> checkAppointmentAvailability(DateTime dateTimeToCheck, List<String> contactIds){
        Boolean available = true;
        List<EventRelation> eventRelations = [SELECT Id, Event.StartDateTime, Event.EndDateTime FROM EventRelation WHERE RelationId In:contactIds AND
                                              DAY_ONLY(Event.StartDateTime) =:dateTimeToCheck.date()];
        for(EventRelation eventRelation :eventRelations){
            if((eventRelation.Event.StartDateTime.getTime() <= dateTimeToCheck.getTime() && eventRelation.Event.EndDateTime.getTime() > dateTimeToCheck.getTime())){
                available = false; 
            }
        }
        
        List<AppointmentResponse> responseList = new List<AppointmentResponse>();
        responseList.add(new AppointmentResponse(available));
        return responseList;
    }
    
    public class AppointmentRequest {
        @InvocableVariable(
            required=true
            description='Date for which we want to check the slots. The variable needs to be an Apex Date type with format    yyyy-MM-dd.'
        )
        public DateTime dateTimeToCheck;
        @InvocableVariable(
            required=true
            description='Contact or Lead Name that we want to Book appointment with.'
        )
        public List<String> contactIds;
    }
    
    public class AppointmentResponse {
        @InvocableVariable(
            description='Returns true if available else false'
        )
        public Boolean available;
        public AppointmentResponse (Boolean available){
            this.available =available;
        }
    }
}