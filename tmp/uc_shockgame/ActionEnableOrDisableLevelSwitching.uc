class ActionEnableOrDisableLevelSwitching extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool DisableLevelSwitching;

function Variable execute()
{
	super.execute();
	ShockPlayerController(parentScript.Level.GetLocalPlayerController()).LevelSwitchingDisabled = DisableLevelSwitching;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x34
	if(DisableLevelSwitching)
	{
		S = "DISABLE level switching.";
		goto J0x57;
		S = "ENABLE level switching.";
	}
	return;
	@NULL
	Item
	J0x57:

	Item
}

defaultproperties
{
	actionDisplayName="Set whether the level is in a state where it can not be transitioned due to scripting."
	actionHelp="Sets whether the level is in a state where it can not be transitioned due to scripting"
	Category="Level"
}