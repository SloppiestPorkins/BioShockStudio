class ActionRemoveAvailablePlasmid extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name Plasmid;

function Variable execute()
{
	super.execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).RemoveAvailablePlasmid(Plasmid);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Remove plasmid ", string(Plasmid)), " from the player.");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Remove a Plasmids."
	actionHelp="Remove a plasmid from the player."
	Category="Plasmids"
}