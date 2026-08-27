class StickyProjectile extends ExplosiveProjectile implements IDamagee, IPotentialAimTarget
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var private float TriggerRadius;
var private float TimeToArm;
var private float ArmTime;
var private bool IsArmed;
var private config bool bExplodeWhenNearDamager;
var private config bool bOnlyStickToFloors;

// Export UStickyProjectile::execPreTelekinesis(FFrame&, void* const)
native function PreTelekinesis();

function Destroyed()
{
	UnTriggerEffectEvent('ProjectileArmingStarted');
	UnTriggerEffectEvent('ProjectileArmingFinished');
	super(Actor).Destroyed();
	return;
	@NULL
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, bool WasMeleeAttack)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x2C
	/*@Error*/
	Explode();
	return;
	@NULL
	Item
}

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, float DamageChance, optional Actor Damager)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x2C
	/*@Error*/
	Explode();
	return;
	@NULL
	Item
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x15
	if(__NFUN_129__(HasExploded))
	{
		return 2;
		goto J0x18;
		return 0;
		return;
	}
	@NULL
}

function bool ActionBlockedByPawns()
{
	return true;
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

defaultproperties
{
	TriggerRadius=200.0000000
	bExplodeWhenNearDamager=true
}