class ExplosiveProjectile extends ShockProjectile implements IEffectObserver
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var private bool ExplodeOnNextImpact;
var private bool ExplodeOnPawnImpact;
var private float FuseEndTime;
var private float FuseTime;
var private bool bShouldStartFuseOnImpact;
var private float OuterDamageRadius;
var private float InnerDamageRadius;
var private Class<Actor> SpawnableDamageSourceClass;
var private float DamageDuration;
var private float ExplodeNearOtherPawnsRadius;
var private Material LastHitMaterial;
var private Vector LastHitNormal;
var private bool HasExploded;
var private bool bDamageDamager;
var private int ExplosionLock;
var config bool bPropogateDamagerWhenExploding;
var config float MaxExplosionDistanceToPlayer;

// Export UExplosiveProjectile::execExplode(FFrame&, void* const)
native function Explode();

function ExplodeOnNextTick()
{
	FuseEndTime = Level.TimeSeconds;
	return;
	@NULL
	Item
	Item
}

function OnEffectStarted(Actor inStartedEffect)
{
	//native.inStartedEffect;	
	@NULL
}

function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
	return;
}

function OnEffectInitialized(Actor inInitializedEffect)
{
	return;
}

function OnScreenEffectStarted(ReferenceCountedObject inStartedEffect)
{
	return;
}

function OnScreenEffectStopped(ReferenceCountedObject inStoppedEffect)
{
	return;
}

defaultproperties
{
	TargettingSlerpModifier=0.0750000
	HavokCollisionFXMinHitVelocity=0.7500000
	HavokCollisionFXMinTimeBetweenFX=0.4000000
	HavokCollisionFXLODRadius=2048.0000000
}