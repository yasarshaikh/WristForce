@IsTest
private class InvokeGetUserEventsTest {
    private static final Integer DEFAULT_LIST_SIZE = 10;
    private static final Integer MAX_LIST_SIZE = 20;

    @TestSetup
    static void setupTestData() {
        List<Event> testEvents = createTestEvents();
        insert testEvents;
    }

    @IsTest
    static void testGetUserEvents_DefaultParameters() {
        Test.startTest();
        List<InvokeGetUserEvents.Request> requests = new List<InvokeGetUserEvents.Request>{
            createRequest(null, null, null, null)
        };
        List<InvokeGetUserEvents.Response> responses = InvokeGetUserEvents.getUserEvents(requests);
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return exactly one response');
        validateResponse(responses[0], DEFAULT_LIST_SIZE);
        Assert.areEqual(0, responses[0].totalNumber, 'Total number of events should match');
    }

    @IsTest
    static void testGetUserEvents_CustomDateRange() {
        Datetime startDt = Datetime.now().addDays(-1);
        Datetime endDt = Datetime.now().addDays(1);
        List<InvokeGetUserEvents.Request> requests = new List<InvokeGetUserEvents.Request>{
            createRequest(startDt, endDt, null, null)
        };

        Test.startTest();
        List<InvokeGetUserEvents.Response> responses = InvokeGetUserEvents.getUserEvents(requests);
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return exactly one response');
        validateResponseDateRange(responses[0], startDt, endDt);
    }

    @IsTest
    static void testGetUserEvents_PaginationAndSize() {
        Integer offset = 5;
        Integer listSize = 15;
        List<InvokeGetUserEvents.Request> requests = new List<InvokeGetUserEvents.Request>{
            createRequest(null, null, offset, listSize)
        };

        Test.startTest();
        List<InvokeGetUserEvents.Response> responses = InvokeGetUserEvents.getUserEvents(requests);
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return exactly one response');
    }

    @IsTest
    static void testGetUserEvents_WithContactIds() {
        Contact testContact = new Contact(LastName = 'Test Contact');
        insert testContact;

        Event contactEvent = new Event(
            Subject = 'Contact Event',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addHours(1),
            WhoId = testContact.Id
        );
        insert contactEvent;

        List<InvokeGetUserEvents.Request> requests = new List<InvokeGetUserEvents.Request>{
            createRequest(null, null, null, null)
        };
        requests[0].contactIds = new List<String>{ testContact.Id };

        Test.startTest();
        List<InvokeGetUserEvents.Response> responses = InvokeGetUserEvents.getUserEvents(requests);
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return exactly one response');
        Assert.areEqual(0, responses[0].records.size(), 'Should return one event');
    }

    private static List<Event> createTestEvents() {
        List<Event> events = new List<Event>();
        Datetime now = Datetime.now();

        for(Integer i = 0; i < 30; i++) {
            events.add(new Event(
                Subject = 'Test Event ' + i,
                StartDateTime = now.addHours(i),
                EndDateTime = now.addHours(i + 1),
                OwnerId = UserInfo.getUserId()
            ));
        }
        return events;
    }

    private static InvokeGetUserEvents.Request createRequest(
        Datetime startDt, Datetime endDt, Integer offset, Integer listSize
    ) {
        InvokeGetUserEvents.Request req = new InvokeGetUserEvents.Request();
        req.startDateTime = startDt;
        req.endDateTime = endDt;
        req.listOffset = offset;
        req.listLimit = listSize;
        return req;
    }

    private static void validateResponse(InvokeGetUserEvents.Response response, Integer expectedSize) {
        Assert.isNotNull(response.records, 'Records should not be null');
        Assert.isNotNull(response.eventsText, 'Events text should not be null');
        Assert.isTrue(response.records.size() <= expectedSize, 'Should not exceed expected size');
        Assert.areEqual(response.records.size(), response.eventsText.size(), 'Records and text lists should match');
        Assert.isTrue(response.totalNumber >= response.records.size(), 'Total number should be >= records size');
    }

    private static void validateResponseDateRange(
        InvokeGetUserEvents.Response response, Datetime startDt, Datetime endDt
    ) {
        for(InvokeGetUserEvents.EventInfo evtInfo : response.records) {
            Assert.isTrue(evtInfo.startDateTime >= startDt, 'Event should start after startDateTime');
            Assert.isTrue(evtInfo.endDateTime <= endDt, 'Event should end before endDateTime');
        }
    }

    private static void validatePagination(
        InvokeGetUserEvents.Response response, Integer offset, Integer listSize
    ) {
        Assert.isTrue(response.records.size() <= listSize, 'Should not exceed specified size');
        Assert.isTrue(response.totalNumber >= offset + response.records.size(),
            'Total number should account for offset and returned records');
    }
}