@isTest
private class IngestDateUpdaterTest {

    @isTest
    static void testSchedulerExecution() {
        // Create test Account
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Create Jellyfish_Company__c records (without Name, as it's not writeable)
        Jellyfish_Company__c jc1 = new Jellyfish_Company__c(
            sfdc_account_id__c = acct.Id,
            Date_of_First_Data_Ingest_Auto__c = Datetime.now().addDays(-10)
        );

        Jellyfish_Company__c jc2 = new Jellyfish_Company__c(
            sfdc_account_id__c = acct.Id,
            Date_of_First_Data_Ingest_Auto__c = Datetime.now()
        );

        insert new List<Jellyfish_Company__c>{ jc1, jc2 };

        // Create Opportunity of Type 'New Business'
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acct.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'New Business',
            Number_of_Engineers__c = 1 // Required field per validation rule
        );
        insert opp;

        Test.startTest();
        IngestDateUpdater updater = new IngestDateUpdater();
        updater.execute(null);
        Test.stopTest();

        // Verify the Opportunity was updated with the most recent ingest date
        Opportunity updatedOpp = [SELECT Id, Date_of_First_Data_Ingest_Auto__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(jc2.Date_of_First_Data_Ingest_Auto__c, updatedOpp.Date_of_First_Data_Ingest_Auto__c);
    }
}
