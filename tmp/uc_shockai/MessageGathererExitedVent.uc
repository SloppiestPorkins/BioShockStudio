class MessageGathererExitedVent extends Message
	editinlinenew
	hidecategories(Object);

var name GathererLabel;
var name ProtectorLabel;
var name VentLabel;

function Construct(Gatherer theGatherer)
{
	GathererLabel = theGatherer.Label;
	ProtectorLabel = theGatherer.GetProtectorEscort().Label;
	VentLabel = theGatherer.GetCurrentVent().Label;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Gatherer finished exiting a vent.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}