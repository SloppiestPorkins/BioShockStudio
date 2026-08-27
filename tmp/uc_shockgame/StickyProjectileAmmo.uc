class StickyProjectileAmmo extends ExplosiveProjectileAmmo implements IProvideStickyProjectileDamageData
	config(Weapons);

var config float TriggerRadius;
var config float TimeToArm;

function float GetTimeToArm()
{
	return TimeToArm;
	return;
	@NULL
}

function float GetTriggerRadius()
{
	return TriggerRadius;
	return;
	@NULL
}

defaultproperties
{
	TriggerRadius=200.0000000
	TimeToArm=2.0000000
	ProjectileClass=Class'ShockGame.StickyProjectile'
}