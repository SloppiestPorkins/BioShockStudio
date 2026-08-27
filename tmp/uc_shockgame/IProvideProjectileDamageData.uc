interface IProvideProjectileDamageData extends IProvideDamageData implements IProvideDamageData
	native
	parseconfig;

function float GetInitialVelocity()
{
	return;
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
	return;
}

function int GetNumProjectilesToFire()
{
	return;
}

function float GetSpreadAngleOfFire()
{
	return;
}

function bool ShouldDestroyOnImpact()
{
	return;
}

function float GetVisibilityDelay()
{
	return;
}

function bool ShouldHeatSeek()
{
	return;
}
