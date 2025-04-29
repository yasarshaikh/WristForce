@IsTest
private class InvokeGetOpportunityApprovalStepsTest {
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Test Opp ' + i,
                AccountId = testAccount.Id,
                Amount = 1000 * (i + 1),
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                ApprovalStatus__c = 'Pending'
            ));
        }
        insert opps;
        
        // Create approval processes for opportunities
        List<ProcessInstance> processInstances = new List<ProcessInstance>();
        for(Opportunity opp : opps) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(opp.Id);
            req.setSubmitterId(UserInfo.getUserId());
            Approval.ProcessResult result = Approval.process(req);
        }
    }
    
    @IsTest
    static void testGetPendingApprovalSteps_DefaultValues() {
        // Create request with default values
        InvokeGetOpportunityApprovalSteps.Request req = new InvokeGetOpportunityApprovalSteps.Request();
        
        Test.startTest();
        List<InvokeGetOpportunityApprovalSteps.Response> responses = 
            InvokeGetOpportunityApprovalSteps.getPendingApprovalSteps(new List<InvokeGetOpportunityApprovalSteps.Request>{ req });
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, responses);
        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].records);
        System.assertEquals(5, responses[0].totalNumber);
        System.assertEquals(5, responses[0].records.size());
    }
    
    @IsTest
    static void testGetPendingApprovalSteps_CustomFields() {
        // Create request with custom fields
        InvokeGetOpportunityApprovalSteps.Request req = new InvokeGetOpportunityApprovalSteps.Request();
        req.opportunityFields = new List<String>{
            'Id', 'Name', 'Amount', 'CloseDate',
            'AccountId', 'Account.Name'
        };
        
        Test.startTest();
        List<InvokeGetOpportunityApprovalSteps.Response> responses = 
            InvokeGetOpportunityApprovalSteps.getPendingApprovalSteps(new List<InvokeGetOpportunityApprovalSteps.Request>{ req });
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, responses);
        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].records);
        
        // Verify custom fields are present
        InvokeGetOpportunityApprovalSteps.ApprovalStepInfo firstStep = responses[0].records[0];
        System.assertNotEquals(null, firstStep.opportunity.Amount);
        System.assertNotEquals(null, firstStep.opportunity.CloseDate);
        System.assertNotEquals(null, firstStep.opportunity.Account.Name);
    }
    
    @IsTest
    static void testGetPendingApprovalSteps_InvalidField() {
        // Create request with invalid field
        InvokeGetOpportunityApprovalSteps.Request req = new InvokeGetOpportunityApprovalSteps.Request();
        req.opportunityFields = new List<String>{ 'InvalidField' };
        
        Test.startTest();
        try {
            InvokeGetOpportunityApprovalSteps.getPendingApprovalSteps(new List<InvokeGetOpportunityApprovalSteps.Request>{ req });
            System.assert(false, 'Expected exception was not thrown');
        } catch(InvokeGetOpportunityApprovalSteps.CustomException e) {
            System.assertEquals('Field does not exist: InvalidField', e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPendingApprovalSteps_Pagination() {
        // Create request with pagination
        InvokeGetOpportunityApprovalSteps.Request req = new InvokeGetOpportunityApprovalSteps.Request();
        req.listOffset = 2;
        req.listLimit = 2;
        req.sortField = 'Amount';
        req.sortOrder = 'DESC';
        
        Test.startTest();
        List<InvokeGetOpportunityApprovalSteps.Response> responses = 
            InvokeGetOpportunityApprovalSteps.getPendingApprovalSteps(new List<InvokeGetOpportunityApprovalSteps.Request>{ req });
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, responses);
        System.assertEquals(1, responses.size());
        System.assertEquals(2, responses[0].records.size());
        System.assertEquals(5, responses[0].totalNumber);
        
        // Verify sorting
        Decimal previousAmount = responses[0].records[0].opportunity.Amount;
        for(Integer i = 1; i < responses[0].records.size(); i++) {
            Decimal currentAmount = responses[0].records[i].opportunity.Amount;
            System.assert(currentAmount <= previousAmount, 'Records not properly sorted');
            previousAmount = currentAmount;
        }
    }
    
    @IsTest
    static void testGetPendingApprovalSteps_DateFilters() {
        // Create request with date filters
        InvokeGetOpportunityApprovalSteps.Request req = new InvokeGetOpportunityApprovalSteps.Request();
        req.createdDateAfter = DateTime.now().addDays(-1);
        req.createdDateBefore = DateTime.now().addDays(1);
        
        Test.startTest();
        List<InvokeGetOpportunityApprovalSteps.Response> responses = 
            InvokeGetOpportunityApprovalSteps.getPendingApprovalSteps(new List<InvokeGetOpportunityApprovalSteps.Request>{ req });
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, responses);
        System.assertEquals(1, responses.size());
        System.assertNotEquals(null, responses[0].records);
        System.assertEquals(5, responses[0].totalNumber);
    }
}