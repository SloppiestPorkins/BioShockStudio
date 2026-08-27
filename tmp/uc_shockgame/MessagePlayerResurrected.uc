class MessagePlayerResurrected extends Message
	editinlinenew
	hidecategories(Object);

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "The player has been resurrected.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.BaseResurrectionStation'
}