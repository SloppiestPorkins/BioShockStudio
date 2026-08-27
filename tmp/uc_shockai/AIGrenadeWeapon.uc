class AIGrenadeWeapon extends AIRangedWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	WeaponFireStartOffsetType=3
	WeaponFireStartRotationType=2
	bUseCanHitCaching=true
}