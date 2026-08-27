class MessageDoorOpen extends Message
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
	return "A Door was opened.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockDoor'
}