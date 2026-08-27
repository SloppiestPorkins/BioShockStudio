class MessageObjectPhotographed extends Message
	editinlinenew
	hidecategories(Object);

var name ObjectLabel;
var name ObjectClass;
var int PhotoScore;

function Construct(IPhotographTarget ObjectThatWasPhotographed, int Score)
{
	ObjectLabel = Actor(ObjectThatWasPhotographed).Label;
	ObjectClass = ObjectThatWasPhotographed.Class.Name;
	PhotoScore = Score;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "The Player photographed an interesting Object.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.IPhotographTarget'
}