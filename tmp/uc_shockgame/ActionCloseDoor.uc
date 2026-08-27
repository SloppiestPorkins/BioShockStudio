class ActionCloseDoor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name DoorLabel;
var travel bool ForceClose;

function Variable execute()
{
	local ShockDoor TargetDoor;

	super.execute();
	// End:0x7E
	foreach parentScript.dynamicActorLabel(Class'ShockGame.ShockDoor', TargetDoor, DoorLabel)
	{
		// End:0x66
		if(ForceClose)
		{
			TargetDoor.ForceClose();
			goto J0x7D;
			TargetDoor.GivePermissionToClose();						
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
	S = __NFUN_112__("Close door with label ", string(DoorLabel));
	return;
	@NULL
	Item
}

defaultproperties
{
	DoorLabel="UNSPECIFIED"
	actionDisplayName="Close door."
	actionHelp="Closes door."
	Category="Door"
}