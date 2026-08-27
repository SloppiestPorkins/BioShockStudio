class MessageAIRecognizedPlayer extends Message
	editinlinenew
	hidecategories(Object);

var name AILabel;
var name AIClass;

function Construct(EcologyFighter theAI)
{
	AILabel = theAI.Label;
	AIClass = theAI.Class.Name;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Protector or Aggressor recognized the player.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.EcologyFighter'
}