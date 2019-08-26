public with sharing class Nego360_MarketingEvent_Controller extends NegoptimBaseController {
    
    public Id commercialPlanId;
    public List<EventsWrapper> listEventsWrapper {get; set;}
    public List<SelectOption> eventsTypeOptions {get; set;}
    public List<SelectOption> recordTypeOptions {get; set;}
    public String valueEventType {get; set;} // radio button
    public String[] valuesEventType {get; set;} // checkbox list
    public String valueRecordType {get; set;} // radio button
    public String[] valuesRecordType {get; set;} // checkbox list
	public Map<String, String> mapCodeColor {get; set;}
    private Boolean accessEventFields = true;
    public Set<String> colorCodeSet = new Set<String> {
            '98FB98', // palegreen
            'B0E0E6', // powderblue
            '8470FF', // lightslateblue
            'DC143C', // crimson
        	'39add1', // light blue
            '3079ab', // dark blue
            'c25975', // mauve
            'e15258', // red
            'f9845b', // orange
            '838cc7', // lavender
            '7d669e', // purple
            '53bbb4', // aqua
            '51b46d', // green
            'e0ab18', // mustard
            '637a91', // dark gray
            'f092b0', // pink
            'b7c0c7', // light gray
            '40E0D0', // turquoise
            'F5DEB3', // wheat
            'FA8072', // salmon
            'BC8F8F', // rosybrown
            '32CD32', // limegreen
            'ADFF2F', // greenyellow
            'DDA0DD', // plum
            'FFB6C1', // lightpink
            'DB7093', // palevioletred
            'DA70D6', // orchid
            '9400D3', // darkviolet
            'B0C4DE', // lightsteelblue
            'FFFF00', // yellow
            'D2B48C', // tan
            'FFE4E1', // mistyrose
            '7171C6', // sgi slateblue
            '388E8E', // sgi teal
            'C5C1AA', // sgi brightgray
            '71C671', // sgi chartreuse
            '7D9EC0', // sgi lightblue
            'B22222', // firebrick
            'F08080', // lightcoral
            'FF7D40', // flesh
            'D2691E', // chocolate
            'E3CF57' // banana
    };
    
    public CalendarEvent currentEvent {get; set;}
    public String calendarEventsJSON {get; set;}
    
    public Nego360_MarketingEvent_Controller(ApexPages.StandardController stdController) {
        commercialPlanId = stdController.getId();
        
        valuesEventType = new String[]{};
        valuesRecordType = new String[]{};
        mapCodeColor = new Map<String, String>();
        
        eventsTypeOptions = new List<SelectOption>();
        recordTypeOptions = new List<SelectOption>();
        // select event type and add them in checkbox list
        List<Schema.PicklistEntry> plEventsType = Commercial_Plan__c.Event_Type__c.getDescribe().getPicklistValues();
        List<RecordType> recordTypeList = [SELECT Id, tolabel(Name) FROM RecordType WHERE SobjectType = 'Commercial_Plan__c'];
        
        while(colorCodeSet.size() < plEventsType.size() * recordTypeList.size()) {
            colorCodeSet.add(getRandomColor());
        }
        List<String> colorCodeList = new List<String>(colorCodeSet);
        Integer i = 0;
        for(Schema.PicklistEntry ple : plEventsType) {
            eventsTypeOptions.add(new SelectOption(ple.getValue(), ple.getLabel()));
            // add color code to record type and event type
            for(RecordType item : recordTypeList) {
                mapCodeColor.put(item.Id + ple.getValue(), colorCodeList.get(i));
                i++;
            }
        }
        // select RecordType and add them in checkbox list        
        for(RecordType item : recordTypeList) {
            recordTypeOptions.add(new SelectOption(item.Id, item.Name));
        }
        // call Load events
        loadEvents();
    }
    
    public String getRandomColor() {
        String[] letters = '0123456789ABCDEF'.split('');
        String color = '';
        for (Integer i = 0; i < 6; i++) {
            color += letters[Math.round(Math.random() * 15)];
        }
        return color;
    }
    // Filter on events by types using checkbox filter
    public PageReference loadEvents() {
    	// Check field security
        String[] eventobjsFields = new String [] {'Id', 'Name', getFieldName('Event_Type__c'), getFieldName('Start_Date__c'),
            getFieldName('End_Date__c'), getFieldName('Status__c')};
        // securing the where clause
    	if(checkAccessibility(Commercial_Plan__c.SObjectType, eventobjsFields)) {
            // TODO: set a LIMIT
	        string query= 'SELECT Id, Name, Event_Type__c, Start_Date__c, End_Date__c, RecordTypeId, Status__c';
            query += ' FROM Commercial_Plan__c';
            if(commercialPlanId == null) {
                query += ' WHERE Reference_Year__c = ' + System.today().year();
            } else {
                query += ' WHERE Id = :commercialPlanId';
            }
	        // FILTERS
	        // 
	        // Filter on EventType
	        if(valuesEventType != null  && valuesEventType.size() > 0) {
	        	List<String> eventTypeList = new List<String>();
	        	//securing by variable sanitization
	        	for(String strList : valuesEventType) {
	        		eventTypeList.add(String.escapeSingleQuotes(strList));
	        	}
	            query += ' AND Event_Type__c IN (\'' + String.join(eventTypeList, '\',\'') +'\')';
	        }
            // Filter on RecordType
	        if(valuesRecordType != null && valuesRecordType.size() > 0) {
	         	List<String> recordTypeList = new List<String>();
	        	//securing by variable sanitization
	        	for(String strList : valuesRecordType) {
	        		recordTypeList.add(String.escapeSingleQuotes(strList));
	        	}
	            query += ' AND RecordTypeId IN (\'' + String.join(recordTypeList, '\',\'') +'\')';
	        }
	        List<Commercial_Plan__c> listPlan = Database.query(query);
	        listEventsWrapper = new List<EventsWrapper>();
            CalendarEvent[] events = new CalendarEvent[]{};
            // push events in wrapper
	        for (Commercial_Plan__c item : listPlan) {
	            String beginDate = DateTime.newInstance(item.Start_Date__c.year(), item.Start_Date__c.month(), item.Start_Date__c.day()).format('YYYY-MM-d');
	            String endDate = DateTime.newInstance(item.End_Date__c.year(), item.End_Date__c.month(), item.End_Date__c.day()).format('YYYY-MM-d');
	            EventsWrapper eventsWrapper = new EventsWrapper(item, beginDate, endDate, 'campaign', mapCodeColor.get(item.RecordTypeId + item.Event_Type__c));
	            listEventsWrapper.add(eventsWrapper);
                
                CalendarEvent event = new CalendarEvent();
                event.mapToCalendarEvent(item, mapCodeColor.get(item.RecordTypeId + item.Event_Type__c));
                events.add(event);
	        }
            // HOLIDAYS
            Integer currentYear = System.today().year();
            String query2 = 'SELECT Id, Name, Description, IsAllDay, ActivityDate, StartTimeInMinutes, EndTimeInMinutes,';
            query2 += ' IsRecurrence, RecurrenceStartDate, RecurrenceEndDateOnly, RecurrenceType, RecurrenceInterval,';
            query2 += ' RecurrenceDayOfWeekMask, RecurrenceDayOfMonth, RecurrenceInstance, RecurrenceMonthOfYear';
            query2 += ' FROM Holiday';
            query2 += ' WHERE ActivityDate >= ' + currentYear + '-01-01';
            query2 += ' AND ActivityDate <= ' + currentYear + '-12-31';
            for(Holiday item : Database.query(query2)) {
                if(!item.IsRecurrence) {
                    item.RecurrenceEndDateOnly = item.ActivityDate;
                }
                CalendarEvent event = new CalendarEvent();
                event.mapToCalendarEvent(item);
                events.add(event);
            }
            calendarEventsJSON = JSON.serialize(events);
            calendarEventsJSON = calendarEventsJSON.replace('startString', 'start');
            calendarEventsJSON = calendarEventsJSON.replace('endString', 'end');
    	}
        return null;
    }
    
    public PageReference add() {
        String eventId = Apexpages.currentPage().getParameters().get('id');
        String title = Apexpages.currentPage().getParameters().get('title');
        String startDate = Apexpages.currentPage().getParameters().get('startDate');
        String endDate = Apexpages.currentPage().getParameters().get('endDate');
        currentEvent = new CalendarEvent(eventId, title, startDate, endDate);
        try {
            upsert currentEvent.mapToCommercialPlan(valueRecordType, valueEventType);
        } catch(Exception e) {
        }
        
        return null;
    }
    // Holidays & Vacations
    @RemoteAction
    public static string getHolidays() {
        String[] fields = new String[] {'Id', 'Name'};
        CalendarEvent[] events = new CalendarEvent[]{};
        Integer currentYear = System.today().year();
        String query = 'SELECT Id, Name, Description, IsAllDay, ActivityDate, StartTimeInMinutes, EndTimeInMinutes,';
        query += ' IsRecurrence, RecurrenceStartDate, RecurrenceEndDateOnly, RecurrenceType, RecurrenceInterval,';
        query += ' RecurrenceDayOfWeekMask, RecurrenceDayOfMonth, RecurrenceInstance, RecurrenceMonthOfYear';
        query += ' FROM Holiday';
        query += ' WHERE ActivityDate >= ' + currentYear + '-01-01';
        query += ' AND ActivityDate <= ' + currentYear + '-12-31';
        for(Holiday item : Database.query(query)) {
            if(!item.IsRecurrence) {
                item.RecurrenceEndDateOnly = item.ActivityDate;
            }
            Time.newInstance(0, 0, 0, 0);
            CalendarEvent event = new CalendarEvent();
            event.mapToCalendarEvent(item);
            events.add(event);
        }
        string jsonEvents = JSON.serialize(events);
        jsonEvents = jsonEvents.replace('startString', 'start');
        jsonEvents = jsonEvents.replace('endString', 'end');
        return jsonEvents;
    }
    
    public void resetFilter() {
    	valuesRecordType = Null;
    	valuesEventType = Null;
    	loadEvents();
    }
    
    // Class to hold calendar event data
    public class CalendarEvent {
        public String id {get;set;}
        public String title {get;set;}
        public Boolean allDay {get;set;}
        public String startString {get;set;}
        public String endString {get;set;}
        public String url {get;set;}
        public String className {get;set;}
        public String rendering {get;set;}
        public String color {get;set;}
        
        String dtFormat = 'yyyy-MM-dd HH:mm:ss';
        
        public CalendarEvent() {
            
        }
        
        public CalendarEvent(String eId, String title, String s, string e) {
            this.id = eId;
            this.title = title;
            this.allDay = true;
            this.startString = s;
            this.endString = e;
        }
        
        public void mapToCalendarEvent(Holiday h) {
            this.id = h.Id;
            this.title = h.Name;
            this.allDay = h.IsAllDay;
            this.startString = Datetime.newInstance(h.ActivityDate, Time.newInstance(0, 0, 0, 0)).format(dtFormat);
            this.endString = Datetime.newInstance(h.RecurrenceEndDateOnly, Time.newInstance(24, 0, 0, 0)).format(dtFormat);
            this.url = '/'+ h.Id;
            this.className = h.Name;
            this.rendering = 'background';
        }
        
        public void mapToCalendarEvent(Commercial_Plan__c c, String color) {
            this.id = c.Id;
            this.title = c.Name;
            this.allDay = true;
            this.startString = Datetime.newInstance(c.Start_Date__c, Time.newInstance(0, 0, 0, 0)).format(dtFormat);
            this.endString = Datetime.newInstance(c.End_Date__c, Time.newInstance(24, 0, 0, 0)).format(dtFormat);
            this.url = '/'+ c.Id;
            this.className = 'campaign';
            this.color = '#' + color;
        }
        
        public Commercial_Plan__c mapToCommercialPlan(Id rt, String eventType) {
            Commercial_Plan__c c = new Commercial_Plan__c();
            if(this.id != null && this.id != '') {
                c.Id = System.Id.valueOf(this.id);
            }
            c.Name = this.title;
            c.Start_Date__c = NegoptimDate.parseDate(this.startString);
            c.End_Date__c = NegoptimDate.parseDate(this.endString);
            c.RecordTypeId = rt;
            c.Event_Type__c = eventType;
            return c;
        }
    }
    
    /* wrapper class for events */
    public class EventsWrapper {
        
        public Commercial_Plan__c event {get; set;}
        public String url {get; set;}
        public String className {get; set;}
        public String eBDate {get; set;}
        public String eEDate {get; set;}
        public String colorCode {get; set;}
        
        public EventsWrapper(Commercial_Plan__c event, String eBDate, String eEDate, String className, String colorCode) {
            this.event = event;
            this.eBDate = eBDate; 
            this.eEDate = eEDate;
            this.url = '/' + event.Id;
            this.className = className;
            this.colorCode = colorCode;
        }
    }
}