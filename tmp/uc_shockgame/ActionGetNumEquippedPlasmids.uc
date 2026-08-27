class ActionGetNumEquippedPlasmids extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Plasmid.ePlasmidTrack Track;

function Variable execute()
{
	super.execute();
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).NumEquippedPlasmids(Track)));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x5E
	if(__NFUN_154__(int(Track), int(0)))
	{
		S = "Get the number of plasmids that are equipped by the player.";
		goto J0xCA;
		S = __NFUN_168__(__NFUN_168__("Get the number of", string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Track)))), "plasmids that are equipped by the player.");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Get the number of plasmids equipped by the player."
	actionHelp="Get the number of plasmids equipped by the player."
	returnType=Class'Scripting.Variable'
	Category="Plasmids"
}