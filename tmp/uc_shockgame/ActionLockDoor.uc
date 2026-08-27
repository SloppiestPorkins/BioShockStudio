class ActionLockDoor extends Action
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
		TargetDoor.Lock();				
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
	S = __NFUN_112__(__NFUN_112__("Lock door with label ", string(DoorLabel)), ".");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Lock door."
	actionHelp="Locks door."
	Category="Door"
}