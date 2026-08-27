class DamageFactory extends Object
	abstract
	native;

enum ECanHitTraceResult
{
	kHitNothing,                    // 0
	kHitTarget,                     // 1
	kHitSomethingOtherThanTarget    // 2
};

function bool CanHit(Actor tester, Actor Target, Vector sourceLocation, out Rotator sourceRotation, IProvideDamageData DamageData)
{
	//native.tester;
	//native.Target;
	//native.sourceLocation;
	//native.sourceRotation;
	//native.DamageData;	
	@NULL
	@NULL
	return default.@NULL;
}

function InitiateDamage(Actor Damager, Vector StartLocation, Rotator StartRotation, IProvideDamageData DamageData, name EffectEventName, out Vector EndLocation)
{
	//native.Damager;
	//native.StartLocation;
	//native.StartRotation;
	//native.DamageData;
	//native.EffectEventName;
	//native.EndLocation;	
	@NULL
	@NULL
	return default.@NULL;
}

overloaded function DealRadiusDamage()
{
	return;
}

function DealRadiusDamage(Actor Damager, Vector Origin, float InnerRadius, float OuterRadius, name DamageStimuliSetName, optional float CritChance)
{
	//native.Damager;
	//native.Origin;
	//native.InnerRadius;
	//native.OuterRadius;
	//native.DamageStimuliSetName;
	//native.CritChance;	
	@NULL
	Holdable
	130
	@NULL
}

function DealRadiusDamage(Actor Damager, Vector Origin, float InnerRadius, float OuterRadius, DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, optional float CritChance)
{
	//native.Damager;
	//native.Origin;
	//native.InnerRadius;
	//native.OuterRadius;
	//native.DamageType;
	//native.DamageAmount;
	//native.CritChance;	
	@NULL
	Holdable
	130
	@NULL
}

function DealSimpleDamage(Actor Damager, IDamagee DamageReceiver, DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, optional float CritChance)
{
	//native.Damager;
	//native.DamageReceiver;
	//native.DamageType;
	//native.DamageAmount;
	//native.CritChance;	
	@NULL
	Holdable
	2
	@NULL
}
