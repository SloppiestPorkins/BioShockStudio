class ActionSetPlayerInvincibility extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool bInvincible;

function Variable execute()
{
	parentScript.Level.GetLocalPlayerController().bGodMode = bInvincible;
	super.execute();
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x31
	if(bInvincible)
	{
		S = "Player is invincible.";
		goto J0x56;
		S = "Player is not invincible.";
	}
	return;
	@NULL
	Variable
	J0x56:

	Variable
}

defaultproperties
{
	bInvincible=true
	actionDisplayName="Make player invincible (god mode)"
	actionHelp="Sets whether the player is invincible (god mode) or not."
	Category="Player"
}