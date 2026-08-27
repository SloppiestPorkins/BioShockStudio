class MessageAssassinTeleportedOut extends Message
	editinlinenew
	hidecategories(Object);

var name AssassinLabel;
var string TeleportGoalName;

function Construct(Assassin Assassin, string inTeleportGoalName)
{
	AssassinLabel = Assassin.Label;
	TeleportGoalName = inTeleportGoalName;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "An Assassin teleported out.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}