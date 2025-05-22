# Ingest Date Updater

This project contains a scheduled Apex job that ensures all **New Business Opportunities** are stamped with the most recent `Date_of_First_Data_Ingest_Auto__c` from related `Jellyfish_Company__c` records.

## 🧠 Project Overview

- For each `Account`, the most recent `Date_of_First_Data_Ingest_Auto__c` is identified from associated `Jellyfish_Company__c` records.
- All open `Opportunities` of **Type = "New Business"** for that `Account` are updated with this timestamp.
- This logic is packaged in a `Schedulable` Apex class and tested with a unit test class.

## 📁 Project Structure

force-app/
└── main/
└── default/
└── classes/
├── IngestDateUpdater.cls
├── IngestDateUpdater.cls-meta.xml
├── IngestDateUpdaterTest.cls
└── IngestDateUpdaterTest.cls-meta.xml

sql
Copy
Edit

🛠 Components (Updated)
IngestDateUpdater.cls
A Schedulable Apex class that:

Gathers all Jellyfish_Company__c records with non-null Date_of_First_Data_Ingest_Auto__c.
Deduplicates to retain only the most recent ingest date per Account.
Queries all open Opportunities of Type = 'New Business'.
Updates two fields on each matching Opportunity:
Date_of_First_Data_Ingest_Auto__c ← from Jellyfish Company
First_Data_Ingest_Date_Set_on_Date__c ← set to Datetime.now() to track when the update occurred
This logic runs safely in bulk and is designed for daily execution.

### `IngestDateUpdaterTest.cls`

Covers:
- Creation of dummy data (Account, Jellyfish_Company__c, Opportunity)
- Execution of the updater logic
- Assertion that the Opportunity field was correctly updated

## 🧪 Running Tests

```bash
sf project deploy start \
  --target-org ProductionOrg \
  --source-dir force-app \
  --test-level RunSpecifiedTests \
  --tests IngestDateUpdaterTest
⏰ Scheduling the Job
To run the job daily at 7:00 AM, use the following anonymous Apex:

apex
Copy
Edit
String cronExpr = '0 0 7 * * ?';
System.schedule('Daily_IngestDateUpdater_7AM', cronExpr, new IngestDateUpdater());
🔐 Notes
Field Name on Jellyfish_Company__c is not writeable and is excluded from test data.

Number_of_Engineers__c is required on Opportunity and must be populated in test data.

🧼 Cleanup
To unschedule the job, find the Job ID using:

bash
Copy
Edit
sf apex run --target-org ProductionOrg --code "System.debug([SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'Daily_IngestDateUpdater_7AM']);"
Then abort the job using:

bash
Copy
Edit
sf apex run --target-org ProductionOrg --code "System.abortJob('<JobId>');"
yaml
Copy
Edit

---