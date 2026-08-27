class MessageAtlasTeleports extends Message
	editinlinenew
	hidecategories(Object);

var int TeleportCounter;

function Construct(int _TeleportCounter)
{
	TeleportCounter = _TeleportCounter;
	return;
	@NULL
	CommanderAction
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "Atlas starting to teleport back to his machine.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}