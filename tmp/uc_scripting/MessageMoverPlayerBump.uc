class MessageMoverPlayerBump extends MessageMover
	editinlinenew
	hidecategories(Object);

var name playerLabel;

function Construct(name _moverLabel, name _playerLabel)
{
	moverLabel = _moverLabel;
	playerLabel = _playerLabel;
	return;
	@NULL
	Variable
	GetPropertyTextByName
	@NULL
}

function string editorDisplay(name TriggeredBy, Message filter)
{
	return __NFUN_112__("The player bumps mover ", string(TriggeredBy));
	return;
	@NULL
}
