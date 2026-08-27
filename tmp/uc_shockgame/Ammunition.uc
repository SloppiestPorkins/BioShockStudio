class Ammunition extends Collectable implements IProvideDamageData
	abstract
	native
	config(Weapons);

var config Class<DamageFactory> DamageModel;
var config name DamageStimuliSetName;
var config float ChanceToCrit;
var config int RequiredNumSlotsToBeUnlocked;
var config int NumRoundsUsedPerShot;
var config int NumBurstShots;
var config Range RandomRangeBurstShots;
var config Range RandomRangeBetweenBurstShots;
var config bool UseFullAuto;
var config float AttackRange;
var config StaticMesh VisualAmmoModel;
var config Material VisualAmmoModelSkinOverride;
var config name AmmoSpecificDamageAmplificationPercentBonusModGroup;
var private config Range HitspangDelayRange;
var private float NextHitspangTime;

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

function ModifyDamageStimuli(out DamageStimuliSet DamageStimuli, Actor Instigator, Actor Damagee)
{
	local int i;
	local ShockPlayer InstigatorPlayer;
	local float DamageAmplification;

	InstigatorPlayer = ShockPlayer(Instigator);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11E
	/*@Error*/
	DamageAmplification = InstigatorPlayer.ModifyStat('WeaponDamageAmplification_PercentBonus', 1.0000000);
	// End:0xA4
	if(__NFUN_255__(AmmoSpecificDamageAmplificationPercentBonusModGroup, 'None'))
	{
		DamageAmplification = InstigatorPlayer.ModifyStat(AmmoSpecificDamageAmplificationPercentBonusModGroup, DamageAmplification);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11E
		/*@Error*/
		__NFUN_182__(DamageStimuli.Stimulus[i].Amount, DamageAmplification);
	}
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0xAF;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool ShouldPlayHitSpang(float CurrentTime)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6C
	/*@Error*/
	NextHitspangTime = __NFUN_174__(CurrentTime, RandRange(HitspangDelayRange.Min, HitspangDelayRange.Max));
	return true;
	return false;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DamageStimuliSetName="DefaultStimuliSet"
	ChanceToCrit=0.1000000
	NumRoundsUsedPerShot=1
	NumBurstShots=1
	VisualAmmoModel=StaticMesh'ShockGame.SimpleShapes.Cube256Diameter'
	Description="Item Description Not Yet Configured In Weapons.ini for this Ammunition"
	FriendlyName="The 'FriendlyName' field needs to be configured in Weapons.ini for this Ammunition"
	ItemDisplayCategory="Ammo"
}