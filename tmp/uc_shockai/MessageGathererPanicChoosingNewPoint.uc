class MessageGathererPanicChoosingNewPoint extends Message
	editinlinenew
	hidecategories(Object);

var name GathererLabel;

function Construct(Gatherer Gatherer)
{
	GathererLabel = Gatherer.Label;
	return;
	@NULL
	CommanderAction
	AIEventNotification
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A gatherer is about to choose a new point while panicking.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}