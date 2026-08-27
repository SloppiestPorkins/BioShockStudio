class SummonProtectorAbility extends ProjectileAttackAbility
	config(Abilities);

defaultproperties
{
	ProjectileClass=Class'ShockGame.ShockDesignerClasses.SummonGathererDartProjectile'
	bShouldHeatSeek=true
	DamageStimuliSetName="SummonProtectorStimuliSet"
	MagicBulletRadius=0.1000000
	MagicBulletChance=1.0000000
	ModGroupName="SummonProtector_Exists"
	BioAmmoCost=100.0000000
	FriendlyName="Hypnotize Big Daddy"
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