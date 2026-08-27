class RosieGrenadeWeaponProjectile extends StickyProjectile
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

defaultproperties
{
	bExplodeWhenNearDamager=false
	bOnlyStickToFloors=true
	RotationPerSecond=(Pitch=196605,Yaw=131070,Roll=0)
	bApplyNormalGravityAfterImpact=true
	StimuliSetToBeAppliedWhenCaughtByTelekinesis="StickyProxStimuliSet"
	StaticMesh=StaticMesh'WP_GrenadeLauncher.Ammo_Pickup_StickyMineProx'
	DrawScale=2.0000000
	CollisionRadius=12.0000000
	CollisionHeight=12.0000000
}