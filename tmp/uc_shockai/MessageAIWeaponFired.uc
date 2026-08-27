class MessageAIWeaponFired extends Message
	editinlinenew
	hidecategories(Object);

var name AILabel;
var name WeaponLabel;
var Class<Weapon> weaponClass;

function Construct(ShockAI AI, Weapon Weapon)
{
	AILabel = AI.Label;
	WeaponLabel = Weapon.Label;
	weaponClass = Weapon.Class;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "An AI fired a weapon.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}