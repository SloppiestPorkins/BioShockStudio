class ActionUnEquipAllPlasmids extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).UnEquipAllPlasmids();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Unequip all currently equipped plasmids for the player.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Unequip all Plasmids."
	actionHelp="Unequip all currently equipped plasmids for the player."
	Category="Plasmids"
}