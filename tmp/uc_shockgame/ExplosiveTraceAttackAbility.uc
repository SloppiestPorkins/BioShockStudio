class ExplosiveTraceAttackAbility extends TraceAttackAbility implements IProvideExplosiveTraceDamageData
	abstract
	config(Abilities);

var config float InnerExplosiveDamageRadius;
var config float OuterExplosiveDamageRadius;
var config name ExplosiveDamageStimuliSetName;

function float GetInnerExplosiveDamageRadius()
{
	return InnerExplosiveDamageRadius;
	return;
	@NULL
}

function float GetOuterExplosiveDamageRadius()
{
	return OuterExplosiveDamageRadius;
	return;
	@NULL
}

function name GetExplosiveDamageStimuliSetName()
{
	return ExplosiveDamageStimuliSetName;
	return;
	@NULL
}

defaultproperties
{
	InnerExplosiveDamageRadius=99999.0000000
	OuterExplosiveDamageRadius=99999.0000000
}