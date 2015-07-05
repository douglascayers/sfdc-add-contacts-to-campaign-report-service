public class AddContactsToCampaignReportService {

	public void execute( Reports.ReportInstance reportInstance ) {
        execute( reportInstance.getReportResults(), reportInstance.getReportId() );
    }

    public void execute( Reports.ReportResults reportResults, ID reportId ) {

        // look up the campaign id that the contacts from this report
        // should be added as campaign members to
        ID campaignId = getCampaignId( reportId );

        // assuming the report is a tabular report type, get the data details from fact map
        // http://salesforce.stackexchange.com/questions/49446/tabular-report-data-via-analytics-api/49449?stw=2#49449
        Reports.ReportFactWithDetails reportDetails = (Reports.ReportFactWithDetails) reportResults.getFactMap().get('T!T');

        // determine the new contact ids from the report that aren't already campaign members
        Set<ID> contactIds = getNewContactIdsToAddToCampaign( reportDetails, campaignId );

        // add the new contacts to the campaign
        addContactsToCampaign( contactIds, campaignId );

    }

    private void addContactsToCampaign( Set<ID> contactIds, ID campaignId ) {

        System.debug( 'Adding contacts to campaign=' + campaignId + ', contactIds=' + contactIds );
        
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for ( ID contactId : contactIds ) {

            campaignMembers.add( new CampaignMember(
                campaignId = campaignId,
                contactId = contactId
            ));

            if ( campaignMembers.size() >= 200 ) {
                System.debug( 'Inserting campaign members batch' );
                insert campaignMembers;
                campaignMembers.clear();
            }

        }

        if ( campaignMembers.size() > 0 ) {
            System.debug( 'Inserting campaign members batch' );
            insert campaignMembers;
            campaignMembers.clear();
        }

    }

    private Set<ID> getNewContactIdsToAddToCampaign( Reports.ReportFactWithDetails reportDetails, ID campaignId ) {

        System.debug( 'Analyzing report and current campaign members to determine new contacts to add' );
        
        // determine which contacts are already members of this campaign
        Map<ID, Boolean> campaignContactExistsMap = buildCampaignContactExistsMap( campaignId );

        Set<ID> contactIds = new Set<ID>();

        for ( Reports.ReportDetailRow row : reportDetails.getRows() ) {
            
            System.debug( row );
            
            for ( Reports.ReportDataCell cell : row.getDataCells() ) {

                ID contactId = (ID) cell.getValue();
                Boolean contactExistsAsMember = campaignContactExistsMap.get( contactId );

                if ( contactExistsAsMember == null || !contactExistsAsMember ) {
                    contactIds.add( contactId );
                }

            }
        }
        
        System.debug( 'New contact ids to add to campaign: ' + contactIds );

        return contactIds;
    }

    private Map<ID, Boolean> buildCampaignContactExistsMap( ID campaignId ) {

        System.debug( 'Building map of contacts already members of campaign=' + campaignId );
        
        // Identify all existing campaign members that are contacts.
        // CampaignMember object does not support upsert, so we can only create or update.
        // As we iterate through the report rows, we will compare the contact id from report
        // to this map and only capture the contacts that need to be added to the campaign.
        // This will prevent us from trying to insert an existing association and get error.
        // https://success.salesforce.com/ideaview?id=08730000000DaEyAAK
        Map<ID, Boolean> campaignContactExistsMap = new Map<ID, Boolean>();
        for ( CampaignMember member : [select contactId from campaignMember where campaignId = :campaignId and contactId != null]) {
            campaignContactExistsMap.put( member.contactId, true );
        }

        System.debug( 'Existing contact campaign members: ' + campaignContactExistsMap );
        
        return campaignContactExistsMap;
    }

    private String getCampaignId( String reportId ) {
       
        System.debug( 'Looking up campaign id from report id in custom setting: ' + reportId );
        
        // Ensure we use the 15 character id to match the value in the custom setting
        // that the salesforce administrator configured, which they usually do by
        // copying from the end of the URL of the saved report.
        if ( reportId.length() > 15 ) {
            reportId = reportId.substring( 0, 15 );
        }
        
        AddContactsToCampaignReportSettings__c settings = AddContactsToCampaignReportSettings__c.getInstance( reportId );

        if ( settings == null || String.isBlank( settings.campaign_id__c ) ) {
            throw new AddContactsToCampaignReportException(
                'No Campaign ID could be determined for Report ID ' + reportId + '. ' +
                'Please add an entry to the AddContactsToCampaignReportSettings__c custom setting.'
            );
        }

        System.debug( 'Campaign ID = ' + settings.campaign_id__c );
        
        return settings.campaign_id__c;
    }

    public class AddContactsToCampaignReportException extends Exception {}

}