Add Contacts to Campaign via Report Subscription
================================================

<a href="https://githubsfdeploy.herokuapp.com?owner=douglascayers&repo=sfdc-add-contacts-to-campaign-report-service">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

This package uses the [Apex Analytics API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_namespace_Reports.htm) to add contacts from a report as campaign members.

**Tammie Silber** [asked on the Success Community](https://success.salesforce.com/0D530000025g9zg) if it was possible to have new contacts automatically added to her campaign based on a daily report she had scheduled.

This turns out to be a great use case for the [Report Notifications features introduced in the Spring '15 release](http://releasenotes.docs.salesforce.com/en-us/spring15/release-notes/rn_salesforce1_reporting_report_notifications_ga.htm). Rather than write apex code with the specific SOQL query criteria in it and which would require redeployments or complex rules engine created to be dynamic anytime the business logic needed to change, we can leverage all the power of Salesforce reports out-of-the-box to narrow down to our desired contacts to add to the campaign. This is awesome because it keeps the control clearly in the administrator's hands using declarative tools he or she is very familiar with. An added benefit of using the report subscription is that this feature can just as easily be disabled at the click of a button if the administrator ever wants to turn it off. With apex triggers, a redeployment would be necessary... yuck!

Speaking of flexibility, this package does utilize a **custom setting** to control which campaign a report should add contacts to as new members. How it works is when the apex code is triggered by the report subscription then it looks up the associated **Campaign ID** by finding the custom setting instance whose `Name` value equals the **Report ID**. This keeps maintenance clean and declarative, and supports as many reports and campaigns as you want =)
