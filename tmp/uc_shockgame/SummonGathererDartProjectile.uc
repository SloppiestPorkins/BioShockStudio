class SummonGathererDartProjectile extends CrossbowProjectile
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	MaxAngleOfDeflection=0.0000000
	ChanceToBreak=0.0000000
	IsAPickup=false
	GravityModifier=-1.0000000
	bApplyNormalGravityAfterImpact=true
	TargettingSlerpModifier=0.0350000
	bCanBeCaughtByTelekinesis=false
	OnlyHeatSeekToProtectors=true
	StaticMesh=StaticMesh'ShockGame.FX_tex.BeaconBall'
	FadeInDuration=0.5000000
	DrawScale=4.0000000
	Skins=/* Array type was not detected. */
	HavokDataClass=Class'ShockGame.ShockDesignerClasses.CrossbowBoltProjectileHavokData'
}