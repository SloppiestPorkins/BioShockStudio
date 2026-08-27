class TurretRPGProjectile extends ExplosiveProjectile
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	ShouldUseBallisticsTesting=false
}