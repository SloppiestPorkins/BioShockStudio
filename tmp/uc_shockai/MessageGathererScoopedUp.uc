class MessageGathererScoopedUp extends Message
	editinlinenew
	hidecategories(Object);

var name GathererLabel;
var name ProtectorLabel;

function Construct(Gatherer theGatherer)
{
	GathererLabel = theGatherer.Label;
	ProtectorLabel = theGatherer.GetProtectorEscort().Label;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Gatherer was scooped up by rosie.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}