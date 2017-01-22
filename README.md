Add Contacts to Campaign via Report Subscription
================================================

---------------------------------------

**IMPORTANT: I have a new and improved project at https://github.com/DouglasCAyers/sfdc-add-campaign-members-by-report**

**I recommend everyone to switch to the new project as it has more features, most notably support for reports with more than 2,000 records.**

This is my initial implementation of the Add Contacts / Leads from a Report to a Campaign Service.

Major drawback was being limited by the 2,000 records in the Apex Analytics API.

The new project uses the [SalesforceFoundation](https://github.com/SalesforceFoundation) [ReportService](https://github.com/SalesforceFoundation/CampaignTools/blob/master/src/classes/ReportService.cls) as part of their [CampaignTools](https://github.com/SalesforceFoundation/CampaignTools) package to support all records in a report beyond the 2,000 limit.

---------------------------------------

This package uses the [Apex Analytics API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_namespace_Reports.htm) to add contacts from a report as campaign members.

**Tammie Silber** [asked on the Success Community](https://success.salesforce.com/0D530000025g9zg) if it was possible to have new contacts automatically added to her campaign based on a daily report she had scheduled.

This turns out to be a great use case for the [Report Notifications features introduced in the Spring '15 release](http://releasenotes.docs.salesforce.com/en-us/spring15/release-notes/rn_salesforce1_reporting_report_notifications_ga.htm). Rather than write apex code with the specific SOQL query criteria in it and which would require redeployments or complex rules engine created to be dynamic anytime the business logic needed to change, we can leverage all the power of Salesforce reports out-of-the-box to narrow down to our desired contacts to add to the campaign. This is awesome because it keeps the control clearly in the administrator's hands using declarative tools he or she is very familiar with. An added benefit of using the report subscription is that this feature can just as easily be disabled at the click of a button if the administrator ever wants to turn it off. With apex triggers, a redeployment would be necessary... yuck!

Speaking of flexibility, this package does utilize a **custom setting** to control which campaign a report should add contacts to as new members. How it works is when the apex code is triggered by the report subscription then it looks up the associated **Campaign ID** by finding the custom setting instance whose `Name` value equals the **Report ID**. This keeps maintenance clean and declarative, and supports as many reports and campaigns as you want =)


Installation
===============

* [Deploy from Github](https://githubsfdeploy.herokuapp.com)


Getting Started
===============

*Despite the wording (add contacts to campaign...), this solution supports both Contact and Lead reports.*

1) Deploy these customizations to your sandbox or developer org to test out first. You can use the [Deploy to Salesforce](https://githubsfdeploy.herokuapp.com?owner=douglascayers&repo=sfdc-add-contacts-to-campaign-report-service) button at the top of this page.

2) Create a report in `Tabular` format that contains at least one field from a **Contact** or **Lead**. Please note, `Summary`, `Matrix` or other complex report formats are not supported by this package at this time.

![tabular format](/images/customize_report_tabular.png)

3) Create a **Campaign** that you want the contacts/leads from the report to be added to as members whenever the report runs.

4) Go to **Setup | Develop | Custom Settings** and click `Manage` link next to **Add Contact to Campaign Report Settings**.

![manage settings](/images/manage_custom_setting.png)

5) Click `New` button to add a new custom setting entry. Specify the 15 character **Report ID** from step 2 in the `Name` field then specify the 15 character **Campaign ID** from step 3 in the `Campaign ID` field. The simplest way to obtain these values is to go to the report page and campaign detail page, respectively, and copy the ID from the end of the URLs.

![campaign id](/images/campaign_url_id.png)

![add custom setting](/images/add_custom_setting.png)

6) Go back and run your report from step 2. On the report results page, click on the `Subscribe` button. It should appear just after the `Add to Campaign` button. Ironically enough, this solution has nothing to do with the `Add to Campaign` button -- though you're welcome to use that button to manually add contacts to your campaigns. But if you're still interested in automating the process, keep reading because you're almost done!

![subscribe](/images/subscribe_to_report.png)

7) On the Report Subscription page, this is where you request how often you want your Contact/Lead report to run (e.g. weekdays at 3am) and when you want to be notified (e.g. when record count is greater than zero) and then how you want to be notified when those conditions are met (e.g. chatter post, email, execute a custom action). You can choose as many notification actions you want, but for our usage you must minimally choose `Execute a Custom Action` and select the apex class **AddContactsToCampaignReportAction**. Remember, despite my original branding here (add contacts to campaign...) this supports Contacts and Leads.

![report subscription](/images/report_subscription.png)

8) To test the subscription, click the **Save & Run Now** button. If successful then your campaign should now include all the contacts/leads from the report.
