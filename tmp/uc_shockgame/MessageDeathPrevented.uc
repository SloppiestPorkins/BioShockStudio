class MessageDeathPrevented extends Message
	editinlinenew
	hidecategories(Object);

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "The Player's Death was prevented.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}