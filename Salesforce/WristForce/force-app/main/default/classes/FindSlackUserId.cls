public without sharing class FindSlackUserId {
    
    @InvocableMethod(
        label = 'get slack user Id'
        description = 'Used to fetch slack user'
    )
    public static List<UserResponse> getSlackUserIds(
        List<UserRequest> requests
    ){
        String message = '';
        List<userResponse> responseList = new List<userResponse>();
        for(userRequest request: requests){
            if(request.message.contains('@'+request.userId)){
                message = request.message.replace('@'+request.userId,'<@'+ getSlackUSerId(request.userId)+'>');
            }else{
                message = '<@'+ getSlackUSerId(request.userId)+'> '+request.message;
            }
            responseList.add(new userResponse(message));
        }
         return responseList;
    }
    
    public static String getSlackUSerId(String userId){
        string allstring = 'FIND\'  ' +userId+'*\' RETURNING User';
        List<List<sObject>> searchList = Search.query(allstring);
        system.debug('searchList**'+searchList);
        for (List<SObject> lst : searchList) {
            for (SObject sobj : lst) {
                userId = String.valueOf(sobj.get('id'));
            }
		}
        system.debug('user**'+userid);
        system.debug('user**'+Slack.UserMappingService.getSlackUserId(userId, 'T08ML1X19DX'));
        return Slack.UserMappingService.getSlackUserId(userId, 'T08ML1X19DX');
    }
    
    public class userRequest {
        @InvocableVariable(
            required=true
            description='mentoined userId'
        )
        public String userId;
        @InvocableVariable(
            required=true
            description='message'
        )
        public String message;
    }
    
    public class userResponse {
        @InvocableVariable(
            description='Returns message'
        )
        public String message;
        public userResponse (String message){
            this.message =message;
        }
    }
}