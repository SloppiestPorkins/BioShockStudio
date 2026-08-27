class MolotovGrenadierLiveGrenadeWeaponAmmo extends GrenadierGrenadeWeaponAmmo
	config(Weapons);

defaultproperties
{
	FuseTime=10.0000000
	OuterDamageRadius=200.0000000
	InnerDamageRadius=100.0000000
	ExplodeOnImpact=true
	InitialVelocity=300.0000000
	ProjectileClass=Class'ShockAI.ShockAIClasses.SpawnedGrenadierMolotovWeaponProjectile'
	DamageStimuliSetName="MolotovGrenadierRangedWeaponStimuliSet"
}