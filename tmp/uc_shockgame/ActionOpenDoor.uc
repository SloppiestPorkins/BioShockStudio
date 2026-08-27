class ActionOpenDoor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DoorLabel;
var travel bool StayOpen;

function Variable execute()
{
	local ShockDoor TargetDoor;

	super.execute();
	// End:0x7E
	foreach parentScript.dynamicActorLabel(Class'ShockGame.ShockDoor', TargetDoor, DoorLabel)
	{
		// End:0x66
		if(StayOpen)
		{
			TargetDoor.OpenAndHold();
			goto J0x7D;
			TargetDoor.Open();						
			return none;
			return;
			@NULL
			Item
		}
		Item
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Open door with label ", string(DoorLabel)), ".");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Open door."
	actionHelp="Opens door."
	Category="Door"
}