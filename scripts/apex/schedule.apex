String cronExpr = '0 0 7 * * ?'; // Every day at 7:00 AM
String jobName = 'Daily_IngestDateUpdater_7AM';

System.schedule(jobName, cronExpr, new IngestDateUpdater());
