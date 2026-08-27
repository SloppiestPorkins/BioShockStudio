class MessageDoorButtonPressed extends Message
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
	return "A Door Button was pressed.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.DoorButtonControl'
}