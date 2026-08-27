class MessageAtlasHasKnockedPlayerBack extends Message
	editinlinenew
	hidecategories(Object);

var int KnockBackCounter;

function Construct(int _KnockBackCounter)
{
	KnockBackCounter = _KnockBackCounter;
	return;
	@NULL
	CommanderAction
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "Atlas has finished knocking the player back.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}