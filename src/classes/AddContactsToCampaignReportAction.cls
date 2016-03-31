/**
 * Proof of concept of adding contacts to a campaign by
 * subscribing to report notifications introduced in Spring '15.
 *
 * http://releasenotes.docs.salesforce.com/en-us/spring15/release-notes/rn_salesforce1_reporting_report_notifications_ga.htm
 * http://releasenotes.docs.salesforce.com/en-us/spring15/release-notes/rn_apex_new_classes_methods.htm
 *
 * https://github.com/DouglasCAyers/sfdc-add-contacts-to-campaign-report-service
 */
public class AddContactsToCampaignReportAction implements Reports.NotificationAction {

    public void execute( Reports.NotificationActionContext context ) {

        AddContactsToCampaignReportService service = new AddContactsToCampaignReportService();

        service.execute( context.getReportInstance() );

    }

}