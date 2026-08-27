class ShockProjectile extends Actor implements IAffectedByTelekinesis
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var private IProvideProjectileDamageData ProjectileData;
var private Class<DamageFactory> DamageFactoryClass;
var private Actor Damager;
var config StaticMesh StaticProjectileModel;
var config float GravityModifier;
var config bool ShouldUseBallisticsTesting;
var config Rotator RotationPerSecond;
var config bool bApplyNormalGravityAfterImpact;
var bool bAlreadyHitAPawnThisFrame;
var bool HitHandlingEnabled;
var config int MaxNumberInLevel;
var private float BecomeVisibleTime;
var config bool OnlyTriggerWeaponImpactedEventOnFirstCollision;
var private bool AlreadyTriggeredWeaponImpacted;
var private bool HasBeenCaughtByTelekinesis;
var config name StimuliSetToBeAppliedWhenCaughtByTelekinesis;
var private bool IsCurrentHeldByTelekinesis;
var private float LastTKHeldTime;
var config float TargettingSlerpModifier;
var config bool bCanBeCaughtByTelekinesis;
var private config bool AquireHeatSeekingTargetAfterLaunch;
var private config bool OnlyHeatSeekToProtectors;
var private config bool DontHeatSeekToSecurity;
var private config float HeatSeekingFOVPercent;
var private bool IsRPG;
var private Actor HeatSeekingTarget;
var private Vector FireLocation;
var private Vector FireRotation;
var private float FireFOV;

function PostBeginPlay()
{
	super.PostBeginPlay();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x43
	/*@Error*/
	SetStaticMesh(StaticProjectileModel);
	SetDrawType(8);
	LinkMesh(none);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Actor GetDamager()
{
	return Damager;
	return;
	@NULL
}

function OnDetached()
{
	super.OnDetached();
	__NFUN_262__(true, false, false);
	__NFUN_3970__(1);
	return;
	@NULL
}

function OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	//native.Telekinesis;	
	@NULL
}

function OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	//native.Telekinesis;	
	@NULL
}

function OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	//native.Telekinesis;	
	@NULL
}

function OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
{
	//native.Telekinesis;	
	@NULL
}

event Actor GetAffectedActor()
{
	return self;
	return;
}

function PreTelekinesis()
{
	return;
}

function bool IsAffectedByTelekinesis()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_129__(bHidden), __NFUN_154__(int(Physics), int(1))), bCanBeCaughtByTelekinesis);
	return;
	@NULL
	Item
	Item
}

function EnableHitHandling(bool HitHandlingEnabled)
{
	//native.HitHandlingEnabled;	
	@NULL
}

// Export UShockProjectile::execPreLevelSave(FFrame&, void* const)
native event PreLevelSave();

defaultproperties
{
	ShouldUseBallisticsTesting=true
	HitHandlingEnabled=true
	BecomeVisibleTime=99999997952.0000000
	OnlyTriggerWeaponImpactedEventOnFirstCollision=true
	TargettingSlerpModifier=1.0000000
	bCanBeCaughtByTelekinesis=true
	HeatSeekingFOVPercent=0.5000000
	Physics=1
	DrawType=8
	StaticMesh=StaticMesh'ShockGame.SimpleShapes.Cube256Diameter'
	bAcceptsProjectors=true
	bInGameRenderable=true
	RemoteRole=0
	bHardAttach=true
	bCastSimpleShadow=true
	CollisionRadius=10.0000000
	CollisionHeight=10.0000000
	bCollideActors=true
	bProjTarget=true
	bBlockHavok=true
	Mass=0.2500000
	HavokDataClass=Class'ShockGame.ProjectileRigidBodyData'
	bNeedLifetimeEffectEvents=true
	bCastShadowMapShadow=true
}