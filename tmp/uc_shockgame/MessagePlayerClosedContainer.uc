class MessagePlayerClosedContainer extends Message
	native
	editinlinenew
	hidecategories(Object);

var name ContainerLabel;
var name ContainerClass;

function Construct(Actor ContainerThatIsBeingUsed)
{
	ContainerLabel = ContainerThatIsBeingUsed.Label;
	ContainerClass = ContainerThatIsBeingUsed.Class.Name;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The player has closed a container.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}