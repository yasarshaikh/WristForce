public with sharing class InvokeGetOpportunityApprovalSteps {
    private static final Set<String> DEFAULT_FIELDS = new Set<String>{
        'Id', 'Name', 'Amount', 'StageName', 'AccountId', 
        'Account.Name', 'OwnerId', 'Owner.Name', 'CreatedDate'
    };
    
    public class CustomException extends Exception {}
    
    @InvocableMethod(label='Get Approval Steps (requests) for Opportunities' 
                     description='Returns pending approval steps for Opportunities assigned to current user')
    public static List<Response> getPendingApprovalSteps(List<Request> requests) {
        Request req = requests[0];
        String status = getStatus(req);
        DateTime createdDateAfter = getCreatedDateAfter(req);
        DateTime createdDateBefore = getCreatedDateBefore(req);
        Integer listOffset = getListOffset(req);
        Integer listLimit = getListLimit(req);
        String sortField = getSortField(req);
        String sortOrder = getSortOrder(req);
        Set<String> fields = validateAndGetFields(req.opportunityFields);
        
        Response res = new Response();
        List<Opportunity> opportunities = getPendingOpportunities(status, 
            createdDateAfter, createdDateBefore, listOffset, listLimit, sortField, sortOrder, fields);
        res.totalNumber = getTotalStepsCount(status, createdDateAfter, createdDateBefore);
        res.records = convertToApprovalInfoList(opportunities);
        
        return new List<Response>{ res };
    }
    
    private static Set<String> validateAndGetFields(List<String> requestedFields) {
        if(requestedFields == null || requestedFields.isEmpty()) {
            return DEFAULT_FIELDS;
        }
        
        Set<String> fields = new Set<String>(requestedFields);
        fields.add('Id'); // Always need Id
        
        // Split fields into direct and relationship fields
        Map<String, Set<String>> relationshipFields = new Map<String, Set<String>>();
        Set<String> directFields = new Set<String>();
        
        for(String field : fields) {
            if(field.contains('.')) {
                String[] parts = field.split('\\.');
                String relationshipName = parts[0];
                String fieldName = parts[1];
                
                if(!relationshipFields.containsKey(relationshipName)) {
                    relationshipFields.put(relationshipName, new Set<String>());
                }
                relationshipFields.get(relationshipName).add(fieldName);
            } else {
                directFields.add(field);
            }
        }
        
        // Validate direct fields
        SObjectType opportunityType = Schema.getGlobalDescribe().get('Opportunity');
        Map<String, SObjectField> fieldMap = opportunityType.getDescribe().fields.getMap();
        
        for(String field : directFields) {
            if(!fieldMap.containsKey(field.toLowerCase())) {
                throw new CustomException('Field does not exist: ' + field);
            }
            
            DescribeFieldResult fieldDescribe = fieldMap.get(field.toLowerCase()).getDescribe();
            if(!fieldDescribe.isAccessible()) {
                throw new CustomException('Field is not accessible: ' + field);
            }
        }
        
        // Validate relationship fields
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for(String relationshipName : relationshipFields.keySet()) {
            // Get the related object type
            String relatedObjectName;
            if(relationshipName == 'Account') {
                relatedObjectName = 'Account';
            } else if(relationshipName == 'Owner') {
                relatedObjectName = 'User';
            } else {
                throw new CustomException('Unsupported relationship: ' + relationshipName);
            }
            
            SObjectType relatedType = globalDescribe.get(relatedObjectName);
            Map<String, SObjectField> relatedFieldMap = relatedType.getDescribe().fields.getMap();
            
            for(String fieldName : relationshipFields.get(relationshipName)) {
                if(!relatedFieldMap.containsKey(fieldName.toLowerCase())) {
                    throw new CustomException('Field does not exist on ' + relationshipName + ': ' + fieldName);
                }
                
                DescribeFieldResult fieldDescribe = relatedFieldMap.get(fieldName.toLowerCase()).getDescribe();
                if(!fieldDescribe.isAccessible()) {
                    throw new CustomException('Field is not accessible on ' + relationshipName + ': ' + fieldName);
                }
            }
        }
        
        return fields;
    }
    
    private static String getStatus(Request req) {
        return String.isBlank(req.status) ? 'Pending' : req.status;
    }

    private static DateTime getCreatedDateAfter(Request req) {
        return req.createdDateAfter != null ? req.createdDateAfter : 
            DateTime.now().addDays(-7);
    }

    private static DateTime getCreatedDateBefore(Request req) {
        return req.createdDateBefore != null ? req.createdDateBefore : 
            DateTime.now();
    }
    
    private static String getSortField(Request req) {
        return String.isBlank(req.sortField) ? 'CreatedDate' : req.sortField;
    }
    
    private static String getSortOrder(Request req) {
        return String.isBlank(req.sortOrder) ? 'ASC' : req.sortOrder.toUpperCase();
    }
    
    private static Integer getTotalStepsCount(String status, 
                                            DateTime createdDateAfter, DateTime createdDateBefore) {
        return [
            SELECT COUNT()
            FROM Opportunity
            WHERE ApprovalStatus__c = :status
            AND Current_Approver_Id__c = :UserInfo.getUserId()
        ];
    }
    
    public static List<Opportunity> getPendingOpportunities(String status,
                                                           DateTime createdDateAfter, 
                                                           DateTime createdDateBefore,
                                                           Integer listOffset, 
                                                           Integer listLimit,
                                                           String sortField,
                                                           String sortOrder,
                                                           Set<String> fields) {
        Id approverId = UserInfo.getUserId();
        String query = 'SELECT ' + String.join(new List<String>(fields), ', ') + ' ' +
            'FROM Opportunity ' +
            'WHERE ApprovalStatus__c = :status ' +
            'AND Current_Approver_Id__c = :approverId ' +
            'ORDER BY ' + String.escapeSingleQuotes(sortField) + ' ' + sortOrder + ' ' +
            'LIMIT :listLimit OFFSET :listOffset';
            
        return Database.query(query);
    }
    
    private static Map<Id, ProcessInstanceWorkitem> getWorkItemsByOpportunityId(Set<Id> opportunityIds) {
        Map<Id, ProcessInstanceWorkitem> workItemMap = new Map<Id, ProcessInstanceWorkitem>();
        
        for(ProcessInstanceWorkitem workItem : [
            SELECT Id, ProcessInstance.SubmittedBy.Name, 
                   ProcessInstance.CreatedDate,
                   ProcessInstance.TargetObjectId
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId IN :opportunityIds
            AND ActorId = :UserInfo.getUserId()
        ]) {
            workItemMap.put(workItem.ProcessInstance.TargetObjectId, workItem);
        }
        
        return workItemMap;
    }
    
    private static List<ApprovalStepInfo> convertToApprovalInfoList(List<Opportunity> opportunities) {
        List<ApprovalStepInfo> approvalInfoList = new List<ApprovalStepInfo>();
        
        if(opportunities.isEmpty()) {
            return approvalInfoList;
        }
        
        Map<Id, ProcessInstanceWorkitem> workItemMap = getWorkItemsByOpportunityId(
            new Map<Id, Opportunity>(opportunities).keySet()
        );
        
        for(Opportunity opp : opportunities) {
            ProcessInstanceWorkitem workItem = workItemMap.get(opp.Id);
            if(workItem != null) {
                approvalInfoList.add(new ApprovalStepInfo(
                    workItem.ProcessInstance.SubmittedBy.Name,
                    workItem.ProcessInstance.CreatedDate,
                    opp,
                    workItem.Id
                ));
            }
        }
        
        return approvalInfoList;
    }
    
    private static Integer getListOffset(Request req) {
        return req.listOffset != null ? Math.max(req.listOffset, 0) : 0;
    }
    
    private static Integer getListLimit(Request req) {
        return (req.listLimit != null && req.listLimit > 0 && req.listLimit <= 20) 
            ? req.listLimit : 10;
    }
    
    public class Request {
        @InvocableVariable(Label='Status' Description='Approval Process Status, Pending by default' Required=false)
        public String status;

        @InvocableVariable(Label='Created Date After' Description='Filter by Created Date >= this value. Defaults to 7 days ago if not specified.' Required=false)
        public DateTime createdDateAfter;

        @InvocableVariable(Label='Created Date Before' Description='Filter by Created Date <= this value. Defaults to current date-time if not specified.' Required=false)
        public DateTime createdDateBefore;
        
        @InvocableVariable(Label='List Offset' Description='For result list pagination - how many records to skip from the beginning, 0 by default.' Required=false)
        public Integer listOffset;
        
        @InvocableVariable(Label='List Limit' Description='For result list pagination - max number of Steps to show, must be positive integer <= 20, 10 by default.' Required=false)
        public Integer listLimit;
        
        @InvocableVariable(Label='Sort Field' Description='Field to sort by (e.g., Amount, CloseDate). Defaults to CreatedDate' Required=false)
        public String sortField;
        
        @InvocableVariable(Label='Sort Order' Description='Sort order (ASC or DESC). Defaults to ASC' Required=false)
        public String sortOrder;

        @InvocableVariable(Label='Opportunity Fields' Description='List of Opportunity fields (API Names) to retrieve. If not specified, default fields will be shown.' Required=false)
        public List<String> opportunityFields;
    }
    
    public class Response {
        @InvocableVariable(Label='Approval Steps' Description='Approval Steps')
        public List<ApprovalStepInfo> records;
        
        @InvocableVariable(Label='Total Number' Description='Total number of approval steps matching the filter criteria')
        public Integer totalNumber;
    }
    
    public class ApprovalStepInfo {
        @InvocableVariable public String submitterName;
        @InvocableVariable public DateTime stepInitiatedDate;
        @InvocableVariable public Opportunity opportunity;
        @InvocableVariable public Id workItemId;
        
        public ApprovalStepInfo(String submitterName, 
                               DateTime stepInitiatedDate, 
                               Opportunity opportunity,
                               Id workItemId) {
            this.submitterName = submitterName;
            this.stepInitiatedDate = stepInitiatedDate;
            this.opportunity = opportunity;
            this.workItemId = workItemId;
        }
    }
}