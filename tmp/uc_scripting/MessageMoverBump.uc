class MessageMoverBump extends MessageMover
	editinlinenew
	hidecategories(Object);

var name bumperLabel;

function Construct(name _moverLabel, name _bumperLabel)
{
	moverLabel = _moverLabel;
	bumperLabel = _bumperLabel;
	return;
	@NULL
	Variable
	GetPropertyTextByName
	@NULL
}

function string editorDisplay(name TriggeredBy, Message filter)
{
	return __NFUN_112__(__NFUN_112__("Mover ", string(TriggeredBy)), " is bumped");
	return;
	@NULL
}
