class ActionSetDoorBrokenState extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DoorLabel;
var travel bool IsBroken;

function Variable execute()
{
	local ShockDoor TheDoor;

	super.execute();
	log('Doors', 4, __NFUN_112__("ActionLockDoor. DoorLabel=", string(DoorLabel)));
	TheDoor = ShockDoor(findByLabel(Class'ShockGame.ShockDoor', DoorLabel));
	AssertWithDescription(__NFUN_119__(TheDoor, none), __NFUN_112__("ActionLockDoor was called with a label for a non-existent door. DoorLabel=", string(DoorLabel)));
	TheDoor.SetBrokenState(IsBroken);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x3B
	if(IsBroken)
	{
		S = __NFUN_168__(__NFUN_168__("Sets", string(DoorLabel)), "to broken.");
		goto J0x6A;
		S = __NFUN_168__(__NFUN_168__("Sets", string(DoorLabel)), "to not broken.");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Set door broken state"
	actionHelp="Sets whether or not the door is broken."
	Category="Door"
}