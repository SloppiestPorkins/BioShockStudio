class ActionOpenDoorUsingButton extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DoorButtonControlLabel;

function Variable execute()
{
	local DoorButtonControl TheDoorButtonControl;

	super.execute();
	log('Doors', 4, __NFUN_112__("ActionOpenDoorUsingButton. DoorButtonControlLabel=", string(DoorButtonControlLabel)));
	TheDoorButtonControl = DoorButtonControl(findByLabel(Class'ShockGame.DoorButtonControl', DoorButtonControlLabel));
	AssertWithDescription(__NFUN_119__(TheDoorButtonControl, none), __NFUN_112__("ActionOpenDoorUsingButton was called with a label for a non-existent DoorButtonControl. DoorButtonControlLabel=", string(DoorButtonControlLabel)));
	TheDoorButtonControl.OpenDoor();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Open door using a button that controls it.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Open door using a button that controls it."
	actionHelp="Opens door using a button that controls it."
	Category="Door"
}