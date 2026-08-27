class MessagePlayerPutItemInContainer extends Message
	native
	editinlinenew
	hidecategories(Object);

var name ContainerLabel;
var name ContainerClass;
var name ItemClass;
var int ItemCount;

function Construct(Actor ContainerThatIsBeingUsed, name ItemPutInContainer, int NumberOfItemsPutInContainer)
{
	ContainerLabel = ContainerThatIsBeingUsed.Label;
	ContainerClass = ContainerThatIsBeingUsed.Class.Name;
	ItemClass = ItemPutInContainer;
	ItemCount = NumberOfItemsPutInContainer;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The player has put an item in a container.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}