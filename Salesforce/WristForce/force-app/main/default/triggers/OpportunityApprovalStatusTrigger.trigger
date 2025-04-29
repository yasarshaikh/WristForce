trigger OpportunityApprovalStatusTrigger on Opportunity (after insert, after update) {
    Set<Id> opportunityIds = new Set<Id>();
    for (Opportunity opp : Trigger.new) {
        if (Trigger.isInsert || opp.ApprovalStatus__c != Trigger.oldMap.get(opp.Id).ApprovalStatus__c) {
            //if (opp.ApprovalStatus__c == 'Pending') {
                opportunityIds.add(opp.Id);
            //}
        }
    }
    
    if (opportunityIds.isEmpty()) return;
    
    Map<Id, Id> oppToApproverMap = new Map<Id, Id>();
    
    // Query ProcessInstance and its related StepsAndWorkitems
    List<ProcessInstance> processes = [
        SELECT Id, TargetObjectId,
            (SELECT Id, ActorId, StepStatus 
             FROM StepsAndWorkitems 
             WHERE StepStatus = 'Pending')
        FROM ProcessInstance 
        WHERE TargetObjectId IN :opportunityIds
        AND Status = 'Pending'
    ];
    
    // Get current approver for each opportunity
    for (ProcessInstance pi : processes) {
        if (!pi.StepsAndWorkitems.isEmpty()) {
            // Get the first pending workitem's actor
            oppToApproverMap.put(
                pi.TargetObjectId, 
                pi.StepsAndWorkitems[0].ActorId
            );
        }
    }
    
    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    //for (Id oppId : oppToApproverMap.keySet()) {
    //        oppsToUpdate.add(new Opportunity(
    //            Id = oppId,
    //            Current_Approver_Id__c = oppToApproverMap.get(oppId)
    //        ));
    //}
    for (Id oppId : opportunityIds) {
        Opportunity opp = Trigger.newMap.get(oppId);
        if (opp.ApprovalStatus__c == 'Pending')	{
            oppsToUpdate.add(new Opportunity(
                Id = oppId,
                Current_Approver_Id__c = opp.OwnerId // stub
            ));
        } else {
            oppsToUpdate.add(new Opportunity(
                Id = oppId,
                Current_Approver_Id__c = null
            ));
        }
	}
    
    if (!oppsToUpdate.isEmpty()) {
        update oppsToUpdate;
    }
}