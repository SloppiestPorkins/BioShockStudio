class FragGrenadeProjectile extends ExplosiveProjectile
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	RotationPerSecond=(Pitch=196605,Yaw=131070,Roll=0)
	StaticMesh=StaticMesh'ShockGame.WP_GrenadeLauncher.Ammo_Pickup_Frag'
	DrawScale=2.0000000
	HavokDataClass=Class'ShockGame.ShockDesignerClasses.RPGTurretProjectileHavokData'
}