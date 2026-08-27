class MessageAlternateDoorOpen extends Message
	editinlinenew
	hidecategories(Object);

var name DoorLabel;

function Construct(name inDoorLabel)
{
	DoorLabel = inDoorLabel;
	return;
	@NULL
	Item
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "An Door's alternate opening mode was triggered.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockDoor'
}