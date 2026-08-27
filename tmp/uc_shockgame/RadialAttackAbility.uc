class RadialAttackAbility extends AttackAbility implements IProvideRadialDamageData
	config(Abilities);

var config float AttackRange;

function float GetAttackRange()
{
	return AttackRange;
	return;
	@NULL
}

function bool ShouldDamageDamager()
{
	return false;
	return;
}

defaultproperties
{
	AttackRange=200.0000000
	DamageModel=Class'ShockGame.RadialDamageFactory'
}