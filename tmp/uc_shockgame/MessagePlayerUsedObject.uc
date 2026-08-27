class MessagePlayerUsedObject extends Message
	editinlinenew
	hidecategories(Object);

var name ObjectLabel;
var name ObjectClass;

function Construct(ICanBeUsed ObjectThatWasUsed)
{
	ObjectLabel = Actor(ObjectThatWasUsed).Label;
	ObjectClass = ObjectThatWasUsed.Class.Name;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function string editorDisplay(name TriggeredBy, Message filter)
{
	return __NFUN_112__(__NFUN_112__("The Player started using '", string(TriggeredBy)), "'.");
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'VengeanceShared.ICanBeUsed'
}