class BotShockGun extends BotBaseGun
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

var config Class<Emitter> EffectClass;
var transient Emitter EffectActorInstance;
var private config Range NewBeamDelay;
var transient array<float> BeamNextSpawnTimes;
var private config float BeamFailureDelay;
var private config float BeamTargetChance;
var private config float DamagePerSecond;
var private float LastDamageTime;
var config name BeamImpactEventName;
var config name BeamOriginBoneName;
var config float PostFireWaitTime;
var private bool IsDisabled;

// Export UBotShockGun::execKillEffects(FFrame&, void* const)
native function KillEffects();

function Destroyed()
{
	KillEffects();
	EffectActorInstance.__NFUN_279__();
	super(AIWeapon).Destroyed();
	return;
	@NULL
	CommanderAction
}

function FireWeapon()
{
	BeginFiring();
	__NFUN_256__(PostFireWaitTime);
	return;
	@NULL
}

function SetIsDisabled(bool Disabled)
{
	//native.Disabled;	
	@NULL
}

function bool WeaponHandlesOwnAttack()
{
	return true;
	return;
}

defaultproperties
{
	NewBeamDelay=(Min=2.0000000,Max=3.0000000)
	BeamFailureDelay=0.1000000
	BeamTargetChance=0.5000000
	DamagePerSecond=10.0000000
	BeamImpactEventName="SecBotArc"
	BeamOriginBoneName="Fx"
	PostFireWaitTime=1.0000000
	ChargeTime=3.0000000
	AttackAnimationInfos[0]=(AttackAnimation="NoAttackAnimation",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartOffsetType=3
	bUseCachedCanHitRotation=false
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.BotShockGunAmmo'
	UsesAmmunition=false
	FiringAnim=/* Array type was not detected. */
	FiringFinalShotAnim=/* Array type was not detected. */
	BaseMagazineSize=10000
	BaseAccuracy=7.0000000
	BaseFireRate=1.5000000
	IdlingAnim="SecBot_MGHover"
	AttachBone="MGattach"
	bNeedProtectedTick=true
}