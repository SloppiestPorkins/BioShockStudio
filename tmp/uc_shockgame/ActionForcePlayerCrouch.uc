class ActionForcePlayerCrouch extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool ShouldCrouch;

function Variable execute()
{
	super.execute();
	// End:0x4E
	if(ShouldCrouch)
	{
		parentScript.Level.GetLocalPlayerController().bDuck = 1;
		goto J0x82;
		parentScript.Level.GetLocalPlayerController().bDuck = 0;
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
	S = "Forcibly crouch the player.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Force Player Crouch"
	actionHelp="Forcibly crouch the player."
	Category="Player"
}