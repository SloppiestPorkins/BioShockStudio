class SecurityBeaconAbility extends ProjectileAttackAbility
	config(Abilities);

function float GetBioAmmoCost(ShockPlayer Instigator)
{
	return Instigator.ModifyStat('SecurityBeaconAbilityBioAmmoCost_Bonus', BioAmmoCost);
	return;
	@NULL
	Item
}

defaultproperties
{
	ProjectileClass=Class'ShockGame.FXClass.BeaconProjectile'
	bShouldHeatSeek=true
	DamageStimuliSetName="SecurityBeaconStimuliSet"
	ChanceToCrit=0.0000000
	MagicBulletRadius=0.2000000
	MagicBulletChance=1.0000000
	ModGroupName="SecurityBeacon_Exists"
	BioAmmoCost=5.0000000
	FriendlyName="Security Bullseye"
	FastEquipAnimationName="Irritant_HandEquip"
	SlowEquipAnimationName="Irritant_HandEquip"
	FireAnimationName="Irritant_Fire"
	FinishFireWithEveAnimationName="Irritant_FireEve"
	FinishFireWithoutEveAnimationName="Irritant_FireNoEve"
	IdlingAnimationName[0]="Irritant_Fidget"
	IdlingAnimationName[1]="Irritant_Fidget_AccentA"
	IdlingAnimationWeight[0]=100.0000000
	IdlingAnimationWeight[1]=10.0000000
}