class ActionCanChangeLevel extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local bool CanChangeLevelsNow;

	super.execute();
	CanChangeLevelsNow = ShockPlayerController(parentScript.Level.GetLocalPlayerController()).IsLevelSwitchingEnabled();
	return newTemporaryVariable(Class'Scripting.VariableBool', string(CanChangeLevelsNow));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Get whether the level is in a state where it can be transitioned.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Get whether level is in a state where it can be transitioned."
	actionHelp="Gets whether level is in a state where it can be transitioned."
	returnType=Class'Scripting.VariableBool'
	Category="Level"
}