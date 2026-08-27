class ExplosiveProjectileAmmo extends ProjectileAmmo implements IProvideExplosiveProjectileDamageData
	config(Weapons);

var config float FuseTime;
var config bool bShouldStartFuseOnImpact;
var config float OuterDamageRadius;
var config float InnerDamageRadius;
var config bool ExplodeOnImpact;
var config bool ExplodeOnPawnImpact;
var config Class<Actor> SpawnableDamageSourceClass;
var config float DamageDuration;
var config float ExplodeNearOtherPawnsRadius;

function float GetFuseTime()
{
	return FuseTime;
	return;
	@NULL
}

function bool ShouldStartFuseOnImpact()
{
	return bShouldStartFuseOnImpact;
	return;
	@NULL
}

function float GetOuterDamageRadius()
{
	return OuterDamageRadius;
	return;
	@NULL
}

function float GetInnerDamageRadius()
{
	return InnerDamageRadius;
	return;
	@NULL
}

function bool GetExplodeOnImpact()
{
	return ExplodeOnImpact;
	return;
	@NULL
}

function bool GetExplodeOnPawnImpact()
{
	return ExplodeOnPawnImpact;
	return;
	@NULL
}

function Class<Actor> GetSpawnableDamageSourceClass()
{
	return SpawnableDamageSourceClass;
	return;
	@NULL
}

function float GetDamageDuration()
{
	return DamageDuration;
	return;
	@NULL
}

function float GetExplodeNearOtherPawnsRadius()
{
	return ExplodeNearOtherPawnsRadius;
	return;
	@NULL
}

defaultproperties
{
	FuseTime=1200.0000000
	OuterDamageRadius=500.0000000
	InnerDamageRadius=100.0000000
	ExplodeOnImpact=true
	ExplodeOnPawnImpact=true
	DamageDuration=10.0000000
	ProjectileClass=Class'ShockGame.ExplosiveProjectile'
	ShouldDestroyProjectileOnImpact=false
}