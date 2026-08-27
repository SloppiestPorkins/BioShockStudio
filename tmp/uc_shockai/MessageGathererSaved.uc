class MessageGathererSaved extends Message
	editinlinenew
	hidecategories(Object);

var name GathererLabel;

function Construct(Gatherer theGatherer)
{
	GathererLabel = theGatherer.Label;
	return;
	@NULL
	CommanderAction
	AIEventNotification
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Gatherer was saved by the player.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}