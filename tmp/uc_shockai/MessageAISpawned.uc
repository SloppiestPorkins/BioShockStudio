class MessageAISpawned extends Message
	editinlinenew
	hidecategories(Object);

var name AILabel;
var name AIClass;
var name AIName;

function Construct(ShockAI theAI)
{
	AILabel = theAI.Label;
	AIClass = theAI.Class.Name;
	AIName = theAI.Name;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "An AI was spawned.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}