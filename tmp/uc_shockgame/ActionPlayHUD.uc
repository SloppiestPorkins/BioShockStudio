class ActionPlayHUD extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	thePlayer.ResetUIState();
	thePlayer.Equip(thePlayer.GetHoldable(0), true);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="PLAY the HUD"
	actionHelp="Plays and resets the HUD movie."
	Category="DO NOT USE UNLESS YOU KNOW WHAT YOU ARE DOING"
	bIsGameCritical=false
}