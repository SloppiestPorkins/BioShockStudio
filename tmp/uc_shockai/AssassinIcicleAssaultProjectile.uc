class AssassinIcicleAssaultProjectile extends ExplosiveProjectile
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	GravityModifier=-1.0000000
	RotationPerSecond=(Pitch=196605,Yaw=131070,Roll=0)
	bApplyNormalGravityAfterImpact=true
	StaticMesh=StaticMesh'ShockAI.FX_tex.MagicAssassinProjectile'
	CollisionRadius=6.0000000
	CollisionHeight=6.0000000
}