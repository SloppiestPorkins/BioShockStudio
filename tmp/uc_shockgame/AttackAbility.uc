class AttackAbility extends Ability implements IDamager, IProvideDamageData
	native
	config(Abilities);

var config Class<DamageFactory> DamageModel;
var config name DamageStimuliSetName;
var config float ChanceToCrit;
var private transient ShockPlayer Damager;
var config float AttackRange;
var const config float MagicBulletRadius;
var const config float MouseMagicBulletRadius;
var const config float MagicBulletChance;

function UseAbility(ShockPlayer Instigator)
{
	super.UseAbility(Instigator);
	Damager = Instigator;
	log(,, __NFUN_112__("Using ability", string(Class)));
	InitiateDamage('None');
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool GetPerfectFireStart(ShockPlayer tester, out Vector StartLocation, out Rotator StartRotation, out Vector EffectStartLocation)
{
	//native.tester;
	//native.StartLocation;
	//native.StartRotation;
	//native.EffectStartLocation;	
	@NULL
	@NULL
	return default.@NULL;
}

function bool CanHit(Actor tester, Actor Target, Vector sourceLocation, out Rotator sourceRotation)
{
	//native.tester;
	//native.Target;
	//native.sourceLocation;
	//native.sourceRotation;	
	@NULL
	@NULL
	return default.@NULL;
}

function InitiateDamage(name EffectEventName)
{
	//native.EffectEventName;	
	@NULL
}

function ModifyDamageStimuli(out DamageStimuliSet DamageStimuli, Actor Instigator, Actor Damagee)
{
	return;
}

function float GetAttackRange()
{
	return AttackRange;
	return;
	@NULL
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

defaultproperties
{
	DamageStimuliSetName="DefaultStimuliSet"
	ChanceToCrit=0.5000000
	InterruptsSanctuary=true
}