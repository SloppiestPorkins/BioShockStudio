class MessagePlayerStartedSavingGatherer extends Message
	editinlinenew
	hidecategories(Object);

var name GathererLabel;
var name GathererClass;

function Construct(BaseShockAI GathererTarget)
{
	GathererLabel = GathererTarget.Label;
	GathererClass = GathererTarget.Class.Name;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The player started saving a gatherer.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}