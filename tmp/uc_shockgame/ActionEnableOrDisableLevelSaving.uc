class ActionEnableOrDisableLevelSaving extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool DisableLevelSaving;

function Variable execute()
{
	super.execute();
	// End:0x55
	if(DisableLevelSaving)
	{
		ShockPlayerController(parentScript.Level.GetLocalPlayerController()).DisableSaveGameOption();
		goto J0x90;
		ShockPlayerController(parentScript.Level.GetLocalPlayerController()).EnableSaveGameOption();
	}
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x3D
	if(DisableLevelSaving)
	{
		S = "DISABLE user-initiated savegames.";
		goto J0x69;
		S = "ENABLE user-initiated savegames.";
	}
	return;
	@NULL
	Item
	J0x69:

	Item
}

defaultproperties
{
	actionDisplayName="Enable or disable user-initiated savegames."
	actionHelp="Enables or disables the ability for users to save the game."
	Category="Level"
}