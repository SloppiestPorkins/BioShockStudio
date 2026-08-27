class MessageTurretBecameInActive extends Message
	editinlinenew
	hidecategories(Object);

var name TurretLabel;

function Construct(Turret theTurret)
{
	TurretLabel = theTurret.Label;
	return;
	@NULL
	CommanderAction
	AIEventNotification
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Turret became in-active.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}