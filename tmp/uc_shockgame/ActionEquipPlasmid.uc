class ActionEquipPlasmid extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name Plasmid;
var int slotNumber;

function Variable execute()
{
	super.execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).EquipPlasmid(Plasmid, slotNumber);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Equip plasmid ", string(Plasmid)), " on slot "), string(slotNumber));
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Equip a Plasmids."
	actionHelp="Equip a plasmid on the player."
	Category="Plasmids"
}