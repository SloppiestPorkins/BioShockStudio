class BeaconProjectile extends ShockProjectile
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	GravityModifier=-1.0000000
	TargettingSlerpModifier=0.0350000
	bCanBeCaughtByTelekinesis=false
	DontHeatSeekToSecurity=true
	StaticMesh=StaticMesh'ShockGame.FX_tex.BeaconBall'
	FadeInDuration=0.5000000
	DrawScale=4.0000000
}