/**
 * https://github.com/DouglasCAyers/sfdc-add-contacts-to-campaign-report-service
 */
public class AddContactsToCampaignReportService {

    public void execute( Reports.ReportInstance reportInstance ) {
        execute( reportInstance.getReportResults(), reportInstance.getReportId() );
    }

    public void execute( Reports.ReportResults reportResults, ID reportId ) {

        // look up the campaign id that the contacts/leads from this report
        // should be added as campaign members to
        ID campaignId = getCampaignId( reportId );

        // assuming the report is a tabular report type, get the data details from fact map
        // http://salesforce.stackexchange.com/questions/49446/tabular-report-data-via-analytics-api/49449?stw=2#49449
        Reports.ReportFactWithDetails reportDetails = (Reports.ReportFactWithDetails) reportResults.getFactMap().get('T!T');

        // determine the new contact/lead ids from the report that aren't already campaign members
        Set<ID> contactAndLeadIds = getNewContactAndLeadIdsToAddToCampaign( reportDetails, campaignId );

        addContactsAndLeadsToCampaign( contactAndLeadIds, campaignId );

    }

    private void addContactsAndLeadsToCampaign( Set<ID> contactAndLeadIds, ID campaignId ) {

        System.debug( 'Adding contacts/leads to campaign=' + campaignId + ', contactAndLeadIds=' + contactAndLeadIds );

        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for ( ID recordId : contactAndLeadIds ) {

            Boolean isContactId = ( recordId.getSobjectType() == Contact.sObjectType );
            Boolean isLeadId    = ( recordId.getSobjectType() == Lead.sObjectType );

            campaignMembers.add( new CampaignMember(
                campaignId = campaignId,
                contactId = ( isContactId ) ? recordId : null,
                leadId = ( isLeadId ) ? recordId : null
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

    private Set<ID> getNewContactAndLeadIdsToAddToCampaign( Reports.ReportFactWithDetails reportDetails, ID campaignId ) {

        System.debug( 'Analyzing report and current campaign members to determine new contacts/leads to add' );

        // determine which contacts/leads are already members of this campaign
        Map<ID, Boolean> campaignMemberExistsMap = buildCampaignMemberExistsMap( campaignId );

        Set<ID> contactAndLeadIds = new Set<ID>();

        for ( Reports.ReportDetailRow row : reportDetails.getRows() ) {

            System.debug( row );

            for ( Reports.ReportDataCell cell : row.getDataCells() ) {

                // each cell has a 'label' and a 'value'
                // the 'label' is what is displayed in the report to the user
                // the 'value' usually is the record id the data comes from
                Object value = cell.getValue();

                try {

                    // ocassionally the cell value is not the record id
                    // so this might throw exception parsing string,
                    // in which case we'll ignore this cell and check the next one
                    ID recordId = Id.valueOf( String.valueOf( value ) );

                    Boolean isContactId = ( recordId.getSobjectType() == Contact.sObjectType );
                    Boolean isLeadId    = ( recordId.getSobjectType() == Lead.sObjectType );
                    Boolean recordExistsAsMember = campaignMemberExistsMap.get( recordId );

                    if ( ( isContactId || isLeadId ) && ( recordExistsAsMember == null || !recordExistsAsMember ) ) {
                        contactAndLeadIds.add( recordId );
                    }

                } catch ( Exception e ) {

                    System.debug( LoggingLevel.WARN, 'Report cell value is not parseable as an ID: ' + cell );

                }

            }

        }

        System.debug( 'New contact/lead ids to add to campaign: ' + contactAndLeadIds );

        return contactAndLeadIds;
    }

    /**
     * Queries the members from the campaign and returns a map whose key
     * are the contact or lead ids of the campaign members.
     * The value in the map is always true.
     */
    private Map<ID, Boolean> buildCampaignMemberExistsMap( ID campaignId ) {

        System.debug( 'Building map of contacts already members of campaign=' + campaignId );

        // Identify all existing campaign members that are contacts.
        // CampaignMember object does not support upsert, so we can only create or update.
        // As we iterate through the report rows, we will compare the contact id from report
        // to this map and only capture the contacts that need to be added to the campaign.
        // This will prevent us from trying to insert an existing association and get error.
        // https://success.salesforce.com/ideaview?id=08730000000DaEyAAK
        Map<ID, Boolean> campaignMemberExistsMap = new Map<ID, Boolean>();
        for ( CampaignMember member : [ SELECT contactId, leadId FROM CampaignMember WHERE campaignId = :campaignId ] ) {

            if ( String.isNotBlank( member.contactId ) ) {
                campaignMemberExistsMap.put( member.contactId, true );
            }

            if ( String.isNotBlank( member.leadId ) ) {
                campaignMemberExistsMap.put( member.leadId, true );
            }

        }

        System.debug( 'Existing contact/lead campaign members: ' + campaignMemberExistsMap );

        return campaignMemberExistsMap;
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