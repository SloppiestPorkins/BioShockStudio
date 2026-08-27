class ActionSetHUDDisplayState extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool EnableHUD;

function Variable execute()
{
	local ShockPlayer Player;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	// End:0x75
	if(EnableHUD)
	{
		Player.EnableNormalHudElements();
		goto J0x8C;
		Player.DisableNormalHudElements();
		return none;
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x22
	if(EnableHUD)
	{
		S = "Enable";
		goto J0x35;
		S = "Disable";
	}
	S = __NFUN_112__(S, " the HUD.");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Show or hide the HUD"
	actionHelp="Shows or hides the HUD"
	Category="HUD"
}