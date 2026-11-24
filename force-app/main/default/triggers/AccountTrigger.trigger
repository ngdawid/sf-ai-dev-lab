trigger AccountTrigger on Account(after update) {
  AccountIndustryHandler.syncContactDescriptions(Trigger.new, Trigger.oldMap);
}
