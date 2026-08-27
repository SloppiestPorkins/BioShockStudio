class ActionGetIsDoorIdle extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DoorLabel;

function Variable execute()
{
	local ShockDoor TheDoor;

	super.execute();
	log('Doors', 4, __NFUN_112__("ActionGetIsDoorIdle. DoorLable=", string(DoorLabel)));
	TheDoor = ShockDoor(findByLabel(Class'ShockGame.ShockDoor', DoorLabel));
	AssertWithDescription(__NFUN_119__(TheDoor, none), __NFUN_112__("ActionGetIsDoorIdle was called with a label for a non-existent door. DoorLabel=", string(DoorLabel)));
	return newTemporaryVariable(Class'Scripting.VariableBool', string(TheDoor.isIdle()));
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Get whether the door is idle.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Get whether the door is idle."
	actionHelp="Gets whether the door is idle."
	returnType=Class'Scripting.VariableBool'
	Category="Door"
}