class RPGgrenadeProjectile extends ExplosiveProjectile
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	bCanBeCaughtByTelekinesis=false
	AquireHeatSeekingTargetAfterLaunch=true
	HeatSeekingFOVPercent=0.9000000
	StaticMesh=StaticMesh'ShockGame.WP_GrenadeLauncher.WP_RPG_Projectile'
	DrawScale=2.0000000
}