@isTest
private class AddContactsToCampaignReportServiceTest {
    
    /**
     * When testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @isTest( seeAllData = true )
    static void test_service() {

        // grab an existing report, otherwise we'd have to dynamically create one in this test and
        // I'm not entirely certain how that would be done. Metadata or Tooling API perhaps?
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Add_Contacts_to_Campaign_Report_Test' ]);

        System.assert( reportList.size() > 0, 'Please create a Contact report that includes the Contact ID field and save the report with unique name Add_Contacts_to_Campaign_Report_Test' );
        
        String reportId;
        String campaignId;
                
        // the campaign we'll add members to from the report above
        Campaign campaign = new Campaign(
            name = 'Test Campaign',
            isActive = true
        );
        
        insert campaign;
        
        // the custom setting uses 15 character report ids
        // since that is the length of the ids when copied from browser
        // when viewing a report, therefore we substring the id
        // here to be consistent
        reportId = String.valueOf( reportList.get(0).id ).left( 15 );
        campaignId = String.valueOf( campaign.id ).left( 15 );
        
        AddContactsToCampaignReportSettings__c settings = new AddContactsToCampaignReportSettings__c(
            name = reportId,
            campaign_id__c = campaignId
        );
        
        Database.upsert( settings, AddContactsToCampaignReportSettings__c.Name );
        
        Boolean includeDetails = true;

        Test.startTest();

        Reports.ReportResults reportResults = Reports.ReportManager.runReport( reportId, includeDetails );

        AddContactsToCampaignReportService service = new AddContactsToCampaignReportService();
        service.execute( reportResults, reportId );

        Test.stopTest();

        // ok, let's try to validate this thing...
        Reports.ReportFactWithDetails reportDetails = (Reports.ReportFactWithDetails) reportResults.getFactMap().get('T!T');
        Integer reportRowCount = reportDetails.getRows().size();
        Integer campaignMemberCount = [ select count() from campaignMember where campaignId = :settings.campaign_id__c ];

        System.assert( reportRowCount == campaignMemberCount );

    }

}