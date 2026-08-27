class QuestLog extends Freebie
	native
	config(QuestLogs);

var config localized array<localized string> Entry;
var config name EffectTag;
var config localized string RelevantLevel;
var config name LogType;
var config name Creator;
var config localized string CreatorFriendlyName;
var config string CreatedDate;
var config bool AutoPlayWhenReceived;

defaultproperties
{
	CreatorFriendlyName="CreatorFriendlyName Missing"
	PickedUpEffectEventName="PickedUpQuestLog"
}