class MessageAtlasAdamDrainStarted extends Message
	editinlinenew
	hidecategories(Object);

var int DrainCounter;

function Construct(int _DrainCounter)
{
	DrainCounter = _DrainCounter;
	return;
	@NULL
	CommanderAction
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "Adam drain on Atlas has started.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}