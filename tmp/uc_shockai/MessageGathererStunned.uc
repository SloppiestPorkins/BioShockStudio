class MessageGathererStunned extends Message
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
	return "A Gatherer became stunned due to a protector dying or being destroyed (or maybe was stunned through forcing interactibility through scripting).";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}