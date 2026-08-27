class ActionUnlockDoor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DoorLabel;

function Variable execute()
{
	local ShockDoor TargetDoor;

	super.execute();
	// End:0x57
	foreach parentScript.dynamicActorLabel(Class'ShockGame.ShockDoor', TargetDoor, DoorLabel)
	{
		TargetDoor.unlock();				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Unlock door with label ", string(DoorLabel)), ".");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Unlock door."
	actionHelp="Unlocks door."
	Category="Door"
}