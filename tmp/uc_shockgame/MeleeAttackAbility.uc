class MeleeAttackAbility extends AttackAbility implements IProvideMeleeDamageData
	config(Abilities);

var config float AttackRange;
var config float AttackAngle;

function float GetAttackRange()
{
	return AttackRange;
	return;
	@NULL
}

function float GetAIvsAIMeleeRange()
{
	assert(false);
	return AttackRange;
	return;
	@NULL
}

function float GetAttackAngle()
{
	return AttackAngle;
	return;
	@NULL
}

defaultproperties
{
	AttackRange=200.0000000
	AttackAngle=30.0000000
	DamageModel=Class'ShockGame.MeleeDamageFactory'
}