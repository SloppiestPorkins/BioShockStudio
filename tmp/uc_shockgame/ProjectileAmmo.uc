class ProjectileAmmo extends Ammunition implements IProvideProjectileDamageData
	native
	config(Weapons);

var config float InitialVelocity;
var config Class<ShockProjectile> ProjectileClass;
var config int NumProjectilesToFire;
var config float SpreadAngleOfFire;
var config array<float> CanHitAttackAngles;
var config bool ShouldDestroyProjectileOnImpact;
var config float VisibilityDelay;
var config bool bShouldHeatSeek;

function float GetInitialVelocity()
{
	return InitialVelocity;
	return;
	@NULL
}

function SetInitialVelocity(float NextInitialVelocity)
{
	assert(__NFUN_177__(NextInitialVelocity, 0.0000000));
	InitialVelocity = NextInitialVelocity;
	return;
	@NULL
	Item
	Item
}

function GetAngleIncrementsToTest(out array<float> AngleDegreesIncrementsToTest)
{
	AngleDegreesIncrementsToTest = CanHitAttackAngles;
	return;
	@NULL
	Item
}

function Class<ShockProjectile> GetProjectileClass()
{
	return ProjectileClass;
	return;
	@NULL
}

function int GetNumProjectilesToFire()
{
	return NumProjectilesToFire;
	return;
	@NULL
}

function float GetSpreadAngleOfFire()
{
	return SpreadAngleOfFire;
	return;
	@NULL
}

function bool ShouldDestroyOnImpact()
{
	return ShouldDestroyProjectileOnImpact;
	return;
	@NULL
}

function float GetVisibilityDelay()
{
	return VisibilityDelay;
	return;
	@NULL
}

function bool ShouldHeatSeek()
{
	return bShouldHeatSeek;
	return;
	@NULL
}

defaultproperties
{
	InitialVelocity=2500.0000000
	ProjectileClass=Class'ShockGame.ShockProjectile'
	NumProjectilesToFire=1
	ShouldDestroyProjectileOnImpact=true
	DamageModel=Class'ShockGame.ProjectileDamageFactory'
}