class MessageSecurityAlarmStarted extends Message
	editinlinenew
	hidecategories(Object);

var name SecurityAlarmSourceLabel;
var name SecurityAlarmTargetLabel;

function Construct(name inSecurityAlarmSourceLabel, name inSecurityAlarmTargetLabel)
{
	SecurityAlarmSourceLabel = inSecurityAlarmSourceLabel;
	SecurityAlarmTargetLabel = inSecurityAlarmTargetLabel;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Security Alarm was started.";
	return;
}

defaultproperties
{
	specificTo=Class'Engine.LevelInfo'
}