class MessageDoorKeypadUsed extends Message
	editinlinenew
	hidecategories(Object);

var string Keycode;
var name DoorLabel;

function Construct(string inKeycode, name inDoorLabel)
{
	Keycode = inKeycode;
	DoorLabel = inDoorLabel;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A keycode was entered at a Door Keypad.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.DoorKeypadControl'
}