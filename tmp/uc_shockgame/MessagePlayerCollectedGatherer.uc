class MessagePlayerCollectedGatherer extends Message
	editinlinenew
	hidecategories(Object);

var name GathererLabel;

function Construct(BaseShockAI GathererTarget)
{
	GathererLabel = GathererTarget.Label;
	return;
	@NULL
	Item
	Vector
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The player collected a gatherer.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}