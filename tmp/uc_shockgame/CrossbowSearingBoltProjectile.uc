class CrossbowSearingBoltProjectile extends CrossbowProjectile
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	MaxAngleOfDeflection=0.0000000
	ChanceToBreak=0.7500000
	GravityModifier=-1.0000000
	bApplyNormalGravityAfterImpact=true
	MaxNumberInLevel=20
	StaticMesh=StaticMesh'ShockGame.WP_Crossbow.arrow_antipersonell'
	Skins=/* Array type was not detected. */
	HavokDataClass=Class'ShockGame.ShockDesignerClasses.CrossbowBoltProjectileHavokData'
}