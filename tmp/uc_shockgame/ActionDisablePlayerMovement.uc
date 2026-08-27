class ActionDisablePlayerMovement extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool DisableMovement;

function Variable execute()
{
	local ShockPlayer Player;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	// End:0xF4
	if(DisableMovement)
	{
		parentScript.Level.GetLocalPlayerController().KillMove();
		parentScript.Level.GetLocalPlayerController().KillLean();
		Player.bCanJump = false;
		Player.bCanCrouch = false;
		goto J0x18A;
		parentScript.Level.GetLocalPlayerController().UnKillMove();
		parentScript.Level.GetLocalPlayerController().UnKillLean();
	}
	Player.bCanJump = true;
	Player.bCanCrouch = true;
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
	if(DisableMovement)
	{
		S = "Disable player movement.";
		goto J0x59;
		S = "Reenable player movement.";
	}
	return;
	@NULL
	Item
	J0x59:

	Item
}

defaultproperties
{
	actionDisplayName="Disable player movement."
	actionHelp="Disables the player's ability to move around.  The player can still look and use, but cannot jump or crouch."
	Category="Player"
}