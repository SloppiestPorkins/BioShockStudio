class BerserkRageAbility extends ProjectileAttackAbility
	config(Abilities);

defaultproperties
{
	ProjectileClass=Class'ShockGame.FXClass.EnrageProjectile'
	bShouldHeatSeek=true
	DamageStimuliSetName="BerserkRageStimuliSet"
	ChanceToCrit=0.0000000
	ModGroupName="BerserkRage_Exists"
	BioAmmoCost=5.0000000
	FriendlyName="Enrage"
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