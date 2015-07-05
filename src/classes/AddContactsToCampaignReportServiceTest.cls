@isTest
private class AddContactsToCampaignReportServiceTest {

    // To my knowledge, we can't easily create new reports via apex,
    // so we use the 'seeAllData=true' test annotation attribute.
    @isTest( seeAllData = true )
    static void test_require_custom_setting() {

        // remember, only way we see this report is with 'seeAllData=true'
        List<Report> reportList = new List<Report>([ select id from report where developerName = 'Contact_Campaign_List_Report']);

        String reportId = reportList.get(0).id;
        // remember, we substring to 15 characters for consistency
        reportId = reportId.substring( 0, 15 );
        
        Boolean includeDetails = true;

        // delete all existing campaign members prior running test
        // so that we can validate that when the service code runs
        // it adds the same number of campaign members as rows in report
        AddContactsToCampaignReportSettings__c settings = AddContactsToCampaignReportSettings__c.getInstance( reportId );
        List<CampaignMember> campaignMembers = new List<CampaignMember>([ select id from campaignMember where campaignId = :settings.campaign_id__c ]);
        if ( campaignMembers.size() > 0 ) {
            delete campaignMembers;
        }

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