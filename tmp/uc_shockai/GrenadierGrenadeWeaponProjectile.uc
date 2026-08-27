class GrenadierGrenadeWeaponProjectile extends ExplosiveProjectile
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var private bool CanNeverBeADud;
var private bool TriedToExplode;
var private config float DudLifeSpan;

function OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	super(ShockProjectile).OnTelekinesisStartedThrowing(Telekinesis);
	CanNeverBeADud = true;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

defaultproperties
{
	DudLifeSpan=100.0000000
	RotationPerSecond=(Pitch=196605,Yaw=131070,Roll=0)
	bApplyNormalGravityAfterImpact=true
	StimuliSetToBeAppliedWhenCaughtByTelekinesis="TKFragGrenadeStimuliSet"
	StaticMesh=StaticMesh'WP_GrenadeLauncher.Ammo_Pickup_Frag'
	CollisionRadius=16.0000000
	CollisionHeight=16.0000000
}