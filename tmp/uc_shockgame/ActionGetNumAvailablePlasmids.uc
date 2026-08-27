class ActionGetNumAvailablePlasmids extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Plasmid.ePlasmidTrack Track;

function Variable execute()
{
	super.execute();
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).NumAvailablePlasmids(Track)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x5F
	if(__NFUN_154__(int(Track), int(0)))
	{
		S = "Get the number of plasmids that are available to the player.";
		goto J0xCC;
		S = __NFUN_168__(__NFUN_168__("Get the number of", string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Track)))), "plasmids that are available to the player.");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Get the number of plasmids available to the player."
	actionHelp="Get the number of plasmids available to the player."
	returnType=Class'Scripting.Variable'
	Category="Plasmids"
}