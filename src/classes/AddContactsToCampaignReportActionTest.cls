@isTest
private class AddContactsToCampaignReportActionTest {

    /**
     * When testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_action() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_to_Campaign_Report_Test' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_to_Campaign_Report_Test' );

        // ----------------------------------------
        // TEST DATA SETUP
        // ----------------------------------------

        // you may have to modify the fields/values set
        // to pass any of your org's validation rules

        Account acct = new Account(
            name = 'Test Account'
        );

        insert acct;

        Contact cont = new Contact(
            accountId = acct.id,
            firstName = 'Test',
            lastName = 'Contact'
        );

        insert cont;

        Campaign camp = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );

        insert camp;

        // the setting requires the 15 character ids
        String reportId = String.valueOf( reportList[0].id ).substring( 0, 15 );
        String campaignId = String.valueOf( camp.id ).substring( 0, 15 );
        Boolean includeDetails = true;

        AddContactsToCampaignReportSettings__c setting = new AddContactsToCampaignReportSettings__c(
            name = reportId,
            campaign_id__c = campaignId
        );

        insert setting;

        // Ideas how to create report notification action test from Andy Fawcett and Dominick Medley
        // http://andyinthecloud.com/2015/11/07/supercharging-salesforce-report-subscriptions-with-apex-and-flow/

        Test.startTest();

        Reports.ReportInstance reportInstance = Reports.ReportManager.runAsyncReport( reportId, includeDetails );

        Test.stopTest();

        // Despite what the Salesforce docs say, at this time the Reports.EvaluatedCondition object
        // cannot be constructed; always get error that constructor not defined.
        // Instead, we use a trick to deserialize json into an apex object.

        List<Map<String, Object>> evaluatedConditionsAsObjectList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'aggregateName' => 'RecordCount',
                'aggregateLabel' => 'Record Count',
                'compareTo' => Double.valueOf( 0 ),
                'value' => Double.valueOf( 1 ),
                'operator' => Reports.EvaluatedConditionOperator.GREATER_THAN
            }
        };

        List<Reports.EvaluatedCondition> evaluatedConditions = (List<Reports.EvaluatedCondition>) JSON.deserialize( JSON.serialize( evaluatedConditionsAsObjectList ), List<Reports.EvaluatedCondition>.class );

        Reports.NotificationActionContext context = new Reports.NotificationActionContext(
            reportInstance, new Reports.ThresholdInformation( evaluatedConditions )
        );

        // now we're to the part we actually want to test
        // however, we can't have it be within the Test.startTest() / Test.stopTest()
        // because we already used that above to generate the async report instance.
        // So bear with me here, the Reports API isn't the nicest thing to test with.

		AddContactsToCampaignReportAction action = new AddContactsToCampaignReportAction();
        action.execute( context );

    }

}