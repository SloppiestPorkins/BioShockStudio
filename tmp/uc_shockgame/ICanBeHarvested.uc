interface ICanBeHarvested extends IHaveAContainer implements IHaveAContainer
	native
	parseconfig;

function OnNeedleInserted(Hands Hands)
{
	return;
}

function OnNeedleRemoved(Hands Hands)
{
	return;
}

function OnHarvestingStarted(Hands Hands)
{
	return;
}

function OnHarvestingFinished(Hands Hands)
{
	return;
}

function name GetHandEquippingAnimationName(Hands Hands)
{
	return;
}

function name GetHandLoopingAnimationName(Hands Hands)
{
	return;
}

function name GetHandUnequippingAnimationName(Hands Hands)
{
	return;
}

function float GetHarvestingTime(Hands Hands)
{
	return;
}

function float GetCurrentHarvestAmount(Hands Hands)
{
	return;
}

function float GetMaxHarvestAmount(Hands Hands)
{
	return;
}

function OnHarvestedAmount(float AmountHarvested)
{
	return;
}

function bool ShouldPushHarvestingContext()
{
	return;
}
