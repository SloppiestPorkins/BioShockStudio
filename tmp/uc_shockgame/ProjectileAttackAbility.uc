class ProjectileAttackAbility extends AttackAbility implements IProvideProjectileDamageData
	abstract
	config(Abilities);

var config float InitialVelocity;
var config Class<ShockProjectile> ProjectileClass;
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
	return;
}

function GetAngleIncrementsToTest(out array<float> AngleDegreesIncrementsToTest)
{
	return;
}

function Class<ShockProjectile> GetProjectileClass()
{
	return ProjectileClass;
	return;
	@NULL
}

function int GetNumProjectilesToFire()
{
	return 1;
	return;
}

function float GetSpreadAngleOfFire()
{
	return 0.0000000;
	return;
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
	ShouldDestroyProjectileOnImpact=true
	DamageModel=Class'ShockGame.ProjectileDamageFactory'
}