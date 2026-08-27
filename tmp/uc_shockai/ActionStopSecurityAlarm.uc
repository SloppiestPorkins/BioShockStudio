class ActionStopSecurityAlarm extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var bool bBotsBecomeDormant;

function Variable execute()
{
	super.execute();
	ShockGameInfo(parentScript.Level.Game).GetSecurityManager().StopAlarm(bBotsBecomeDormant);
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Stop any running security alarm";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Stop a Security Alarm"
	actionHelp="Stop a Security Alarm"
	Category="AI"
}