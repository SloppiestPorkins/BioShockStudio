class ActionEnableOrDisableTrainingMessages extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var bool EnableTrainingMessages;

function Variable execute()
{
	local ShockPlayerController PlayerController;

	super.execute();
	PlayerController = ShockPlayerController(parentScript.Level.GetLocalPlayerController());
	PlayerController.SuppressTrainingMessages = __NFUN_129__(EnableTrainingMessages);
	ShockGameDriver(parentScript.Level.GetGameDriver()).GetTrainingMessageManager().ClearTrainingMessage('None');
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x5D
	if(EnableTrainingMessages)
	{
		S = "Enable non-interrupt training messages so they will be displayed.";
		goto J0xC9;
		S = "Disable all non-interrupt training messages from being displayed, and clear all queued messages.";
	}
	return;
	@NULL
	Item
	J0xC9:

	Item
}

defaultproperties
{
	actionDisplayName="Enable or disable all non-interrupt training messages from being displayed."
	actionHelp="Enable or disable all non-interrupt training messages."
	Category="Training"
}