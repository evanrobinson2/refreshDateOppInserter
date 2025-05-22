global class IngestDateUpdater implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Step 1: Get all Jellyfish Company records with ingest dates
        List<Jellyfish_Company__c> allCompanies = [
            SELECT sfdc_account_id__c, Date_of_First_Data_Ingest_Auto__c
            FROM Jellyfish_Company__c
            WHERE Date_of_First_Data_Ingest_Auto__c != NULL
            ORDER BY sfdc_account_id__c, Date_of_First_Data_Ingest_Auto__c DESC
        ];

        // Step 2: Build a map of all ingest dates per account
        Map<Id, List<Datetime>> allIngestsByAccount = new Map<Id, List<Datetime>>();
        Map<Id, Datetime> latestIngestByAccount = new Map<Id, Datetime>();

        for (Jellyfish_Company__c jc : allCompanies) {
            Id accountId = jc.sfdc_account_id__c;
            if (accountId == null) continue;

            if (!allIngestsByAccount.containsKey(accountId)) {
                allIngestsByAccount.put(accountId, new List<Datetime>());
            }
            allIngestsByAccount.get(accountId).add(jc.Date_of_First_Data_Ingest_Auto__c);

            // For deduplication logic
            if (!latestIngestByAccount.containsKey(accountId)) {
                latestIngestByAccount.put(accountId, jc.Date_of_First_Data_Ingest_Auto__c);
            }
        }

        // Step 3: Analyze duplicates
        Integer duplicateCount = 0;
        System.debug('--- Duplicated Accounts and Resolution ---');
        for (Id acctId : allIngestsByAccount.keySet()) {
            List<Datetime> dates = allIngestsByAccount.get(acctId);
            if (dates.size() > 1) {
                duplicateCount++;
                System.debug('AccountId: ' + acctId);
                System.debug('  Selected (most recent): ' + latestIngestByAccount.get(acctId));
                System.debug('  Ignored:');
                for (Datetime dt : dates) {
                    if (dt != latestIngestByAccount.get(acctId)) {
                        System.debug('    - ' + dt);
                    }
                }
            }
        }

        System.debug('--- Summary ---');
        System.debug('Total accounts with duplicate ingest dates: ' + duplicateCount);
        System.debug('Total unique accounts with ingest data: ' + latestIngestByAccount.size());

        // Step 4: Query and update open New Business Opportunities
        List<Opportunity> openOpps = [
            SELECT Id, AccountId, Name, StageName
            FROM Opportunity
            WHERE AccountId IN :latestIngestByAccount.keySet()
            AND IsClosed = FALSE
            AND Type = 'New Business'
        ];

        System.debug('--- Open New Business Opportunities for Affected Accounts ---');
        List<String> oppIds = new List<String>();
        for (Opportunity opp : openOpps) {
            Datetime ingestDate = latestIngestByAccount.get(opp.AccountId);
            System.debug('OppId: ' + opp.Id + ' | Name: ' + opp.Name + ' | AccountId: ' + opp.AccountId + ' | Ingest Date: ' + ingestDate);
            oppIds.add(opp.Id);
            opp.Date_of_First_Data_Ingest_Auto__c = ingestDate;
        }

        update openOpps;
        System.debug('Total open New Business opportunities updated: ' + openOpps.size());
        System.debug('Opportunity IDs: ' + String.join(oppIds, ','));
    }
}
