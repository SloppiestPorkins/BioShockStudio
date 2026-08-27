class ActionEndDLCLevel extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool FailedLevel;

function Variable execute()
{
	local ShockPlayer Player;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	Player.SwitchToDLCEndMenu(FailedLevel);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x38
	if(FailedLevel)
	{
		S = "Complete DLC level (Failed).";
		goto J0x63;
		S = "Complete DLC level (Succeeded).";
	}
	return;
	@NULL
	Item
	J0x63:

	Item
}

defaultproperties
{
	actionDisplayName="End DLC Level"
	actionHelp="Ends a DLC level and goes to the end screen."
	Category="Level"
}