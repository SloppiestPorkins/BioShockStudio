class RangedAggressorChargedBurstWeapon extends AIWeapon
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

var config Range ChargedBurstsInterval;
var config float ChargedBurstsWarningDuration;
var private float ChargedBurstsNextDischargeTime;
var private float ChargedBurstsNextWarningTime;
var private bool bChargedBurstsWarningTriggered;

function PostBeginPlay()
{
	super(Weapon).PostBeginPlay();
	SetupNextChargedBurst();
	return;
	@NULL
}

function Tick(float DeltaTime)
{
	local RangedAggressor OwnerAI;

	super(Actor).Tick(DeltaTime);
	OwnerAI = RangedAggressor(Owner);
	assert(__NFUN_119__(OwnerAI, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x149
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x108
	/*@Error*/
	bChargedBurstsWarningTriggered = true;
	OwnerAI.TriggerEffectEvent('ChargedBurstWarning',,, OwnerAI.Location, OwnerAI.Rotation);
	goto J0x149;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x149
	/*@Error*/
	SetupNextChargedBurst();
	InitiateDamage('None');
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function SetupNextChargedBurst()
{
	ChargedBurstsNextDischargeTime = __NFUN_174__(Level.TimeSeconds, RandRange(ChargedBurstsInterval.Min, ChargedBurstsInterval.Max));
	ChargedBurstsNextWarningTime = __NFUN_175__(ChargedBurstsNextDischargeTime, ChargedBurstsWarningDuration);
	bChargedBurstsWarningTriggered = false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

defaultproperties
{
	ChargedBurstsInterval=(Min=25.0000000,Max=35.0000000)
	ChargedBurstsWarningDuration=1.0000000
	AttackAnimationInfos[0]=(AttackAnimation="NoAttackAnimation",Weight=1.0000000,SourceSocketName="None",AttackAnimationRange=(Min=0.0000000,Max=0.0000000),bCheckFullAnimationMotion=false,bIsCeilingAttackAnimation=false,bUseInitiateDamageRotation=false,bPlayerOnlyAttack=false,bDoNotUseForProjectedTests=false,TimeBetweenUsageOverride=(Min=0.0000000,Max=0.0000000))
	WeaponFireStartRotationType=2
	AvailableAmmoTypes=/* Array type was not detected. */
	DefaultAmmoSelection=Class'ShockAI.RangedAggressorChargedBurstWeaponAmmo'
	UsesAmmunition=false
}