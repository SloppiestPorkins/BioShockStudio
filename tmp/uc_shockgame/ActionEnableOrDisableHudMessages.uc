class ActionEnableOrDisableHudMessages extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool DisableHudMessages;

function Variable execute()
{
	super.execute();
	ShockPlayerController(parentScript.Level.GetLocalPlayerController()).bSuppressHUDMessages = DisableHudMessages;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x31
	if(DisableHudMessages)
	{
		S = "DISABLE HUD Messages.";
		goto J0x51;
		S = "ENABLE HUD Messages.";
	}
	return;
	@NULL
	Item
	J0x51:

	Item
}

defaultproperties
{
	actionDisplayName="Enable or disable HUD Messages."
	actionHelp="Enables or disables HUD Messages."
	Category="Level"
}