class MessagePlayerStartedHarvesting extends Message
	editinlinenew
	hidecategories(Object);

var name HarvestLabel;
var name HarvestClass;

function Construct(ICanBeHarvested HarvestTarget)
{
	HarvestLabel = Actor(HarvestTarget).Label;
	HarvestClass = HarvestTarget.Class.Name;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The player started harvesting adam.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}