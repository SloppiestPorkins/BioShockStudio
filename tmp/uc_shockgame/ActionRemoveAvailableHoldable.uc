class ActionRemoveAvailableHoldable extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var Class<Holdable> HoldableClass;

function Variable execute()
{
	local ShockPlayer thePlayer;

	super.execute();
	thePlayer = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName(HoldableClass.Name));
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Remove Holdable ", string(HoldableClass)), " from the player.");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Remove a Holdable."
	actionHelp="Remove a Holdable from the player."
	Category="Weapon"
}