class MessageKeypadContainerUsed extends Message
	editinlinenew
	hidecategories(Object);

var string Keycode;
var name ContainerLabel;

function Construct(string inKeycode, name inContainerLabel)
{
	Keycode = inKeycode;
	ContainerLabel = inContainerLabel;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A keycode was entered at a container.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.KeypadContainer'
}