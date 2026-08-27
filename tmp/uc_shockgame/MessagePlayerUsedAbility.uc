class MessagePlayerUsedAbility extends Message
	editinlinenew
	hidecategories(Object);

var Class<Ability> abilityClass;

function Construct(Class<Ability> inAbilityClass)
{
	abilityClass = inAbilityClass;
	return;
	@NULL
	Item
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "Ability was used by the player";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.Ability'
}