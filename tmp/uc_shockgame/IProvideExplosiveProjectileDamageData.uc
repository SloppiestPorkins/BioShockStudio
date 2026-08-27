interface IProvideExplosiveProjectileDamageData extends IProvideProjectileDamageData implements IProvideProjectileDamageData
	native
	parseconfig;

function float GetFuseTime()
{
	return;
}

function bool ShouldStartFuseOnImpact()
{
	return;
}

function float GetOuterDamageRadius()
{
	return;
}

function float GetInnerDamageRadius()
{
	return;
}

function bool GetExplodeOnImpact()
{
	return;
}

function bool GetExplodeOnPawnImpact()
{
	return;
}

function Class<Actor> GetSpawnableDamageSourceClass()
{
	return;
}

function float GetDamageDuration()
{
	return;
}

function float GetExplodeNearOtherPawnsRadius()
{
	return;
}
