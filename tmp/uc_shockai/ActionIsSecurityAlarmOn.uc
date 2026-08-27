class ActionIsSecurityAlarmOn extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AlarmTargetLabel;

function Variable execute()
{
	local SecurityManagerBase Manager;

	Manager = ShockGameInfo(parentScript.Level.Game).GetSecurityManager();
	return newTemporaryVariable(Class'Scripting.VariableBool', string(__NFUN_130__(Manager.IsAlarmOn(), __NFUN_132__(__NFUN_254__(AlarmTargetLabel, 'None'), __NFUN_254__(AlarmTargetLabel, Manager.GetAlarmTarget().Label)))));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x42
	if(__NFUN_254__(AlarmTargetLabel, 'None'))
	{
		S = "Get whether the alarm is on.";
		goto J0x8A;
		S = __NFUN_112__(__NFUN_112__("Get whether the alarm is on and targeting ", string(AlarmTargetLabel)), ".");
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Get whether the security alarm is on."
	actionHelp="Gets whether the security alarm is on."
	returnType=Class'Scripting.VariableBool'
	Category="Security"
}