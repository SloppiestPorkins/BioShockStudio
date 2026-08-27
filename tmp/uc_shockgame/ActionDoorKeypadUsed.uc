class ActionDoorKeypadUsed extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DoorKeypadControlLabel;
var travel bool Success;

function Variable execute()
{
	local DoorKeypadControl TheDoorKeypadControl;

	super.execute();
	log('Doors', 4, __NFUN_112__("ActionDoorKeypadUsed. DoorKeypadControlLabel=", string(DoorKeypadControlLabel)));
	TheDoorKeypadControl = DoorKeypadControl(findByLabel(Class'ShockGame.DoorKeypadControl', DoorKeypadControlLabel));
	AssertWithDescription(__NFUN_119__(TheDoorKeypadControl, none), __NFUN_112__("ActionDoorKeypadUsed was called with a label for a non-existent DoorKeypadControl. DoorKeypadControlLabel=", string(DoorKeypadControlLabel)));
	TheDoorKeypadControl.KeypadUsed(Success);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Tell DoorKeypadControl whether keycode was successfully entered or not.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Tell DoorKeypadControl whether keycode was successfully entered or not."
	actionHelp="Tells DoorKeypadControl whether keycode was successfully entered or not."
	Category="Door"
}