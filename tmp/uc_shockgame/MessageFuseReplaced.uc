class MessageFuseReplaced extends Message
	editinlinenew
	hidecategories(Object);

var name FuseLabel;

function Construct(name inFuseLabel)
{
	FuseLabel = inFuseLabel;
	return;
	@NULL
	Item
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Fuse was blown.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.FuseBox'
}