class MessagePlayerDroppedTKedObject extends Message
	editinlinenew
	hidecategories(Object);

static function string editorDisplay(name Instigator, Message filter)
{
	return "The player has dropped an item held by TK.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}