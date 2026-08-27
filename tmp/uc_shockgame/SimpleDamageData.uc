class SimpleDamageData extends Object implements IProvideDamageData
	native
	editinlinenew;

var name DamageStimuliSetName;
var float ChanceToCrit;

function float GetAttackRange()
{
	return 0.0000000;
	return;
}

function name GetDamageStimuliSetName()
{
	return DamageStimuliSetName;
	return;
	@NULL
}

function float GetCritChance()
{
	return ChanceToCrit;
	return;
	@NULL
}

function bool ShouldPlayHitSpang(float CurrentTime)
{
	return true;
	return;
}

function ModifyDamageStimuli(out DamageStimuliSet DamageStimuli, Actor Instigator, Actor Damagee)
{
	return;
}

defaultproperties
{
	DamageStimuliSetName="DefaultStimuliSet"
}