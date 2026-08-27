class MessageAIAttackingTarget extends Message
	editinlinenew
	hidecategories(Object);

var name AILabel;
var name TargetLabel;

function Construct(name inAILabel, name inTargetLabel)
{
	AILabel = inAILabel;
	TargetLabel = inTargetLabel;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Protector or Aggressor is attacking a target.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}