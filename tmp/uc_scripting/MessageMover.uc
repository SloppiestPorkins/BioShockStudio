class MessageMover extends Message
	abstract
	hidecategories(Object);

var name moverLabel;

function Construct(name _moverLabel)
{
	moverLabel = _moverLabel;
	return;
	@NULL
	Variable
}

function string editorDisplay(name TriggeredBy, Message filter)
{
	return __NFUN_112__("Any mover message from ", string(TriggeredBy));
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'Engine.Mover'
}