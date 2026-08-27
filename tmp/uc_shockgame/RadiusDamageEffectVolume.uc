class RadiusDamageEffectVolume extends RadiusEffectVolume
	abstract
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config name DamageStimuliSetName;
var private config float ChanceToCrit;
var private config bool ApplyDamageToOwner;

function DamageStimuliSet GetDamageStimuliSet()
{
	return Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(DamageStimuliSetName);
	return;
	@NULL
	Item
	DifficultyAdjustment
}

function bool IsValidTarget(Actor Target)
{
	return __NFUN_130__(super.IsValidTarget(Target), __NFUN_132__(ApplyDamageToOwner, __NFUN_119__(Target, EffectOwner)));
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function ApplyEffectTo(Actor Target)
{
	local DamageStimuliSet DamageSet;
	local Vector TargetDifference;

	TargetDifference = __NFUN_226__(__NFUN_216__(Target.Location, Location));
	DamageSet = GetDamageStimuliSet();
	ShockPawn(Target).TakeDamage(DamageSet, ChanceToCrit, EffectOwner, Target.Location, vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), 'None', 1.0000000);
	DamageSet.__NFUN_200__();
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	DamageStimuliSetName="DefaultStimuliSet"
	ApplyDamageToOwner=true
}