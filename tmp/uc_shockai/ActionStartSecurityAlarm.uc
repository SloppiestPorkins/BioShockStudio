class ActionStartSecurityAlarm extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TargetLabel;
var travel Class<SecurityBot> SecurityBotClass;
var travel int NumSecurityBotsToSpawn;
var travel bool bForceNewSecurityTarget;
var travel bool bInfiniteAlarm;

function OutputTypesToBox(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplaySecurityBotTypes(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string DisplayAITypeName(Class<ShockAI> AIClass)
{
	// End:0x2B
	if(__NFUN_119__(AIClass, none))
	{
		return string(AIClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3B:

	CommanderAction
}

function Variable execute()
{
	local ShockPawn Target;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10B
	/*@Error*/
	Target = ShockPawn(findByLabel(Class'ShockGame.ShockPawn', TargetLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10B
	/*@Error*/
	ShockGameInfo(parentScript.Level.Game).GetSecurityManager().StartAlarm(parentScript, Target, SecurityBotClass, NumSecurityBotsToSpawn, bForceNewSecurityTarget, bInfiniteAlarm, bInfiniteAlarm);
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x7B
	if(__NFUN_255__(TargetLabel, 'None'))
	{
		S = __NFUN_112__("Start a Security Alarm with the Target being a ShockPawn with the label ", string(TargetLabel));
		goto J0x9E;
		S = "TargetLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	NumSecurityBotsToSpawn=1
	actionDisplayName="Start a Security Alarm"
	actionHelp="Start a Security Alarm"
	Category="AI"
}