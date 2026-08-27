interface IBooty
	native
	parseconfig;

function bool IsUsableAsBooty(Gatherer TestGatherer)
{
	return;
}

function Ragdoll GetRagdoll()
{
	return;
}

function NavigationPoint GetClosestNavigationPoint()
{
	return;
}

function bool GetBestGatherPoint(out Vector BestGatherPoint, out Vector BestGatherPointRigidBodyLocation, out int RigidBodyIndex)
{
	return;
}

function Vector GetUpdatedRigidBodyLocation(int RigidBodyIndex)
{
	return;
}

function Vector GetUpdatedGatherPointLocation(int RigidBodyIndex)
{
	return;
}

function ClaimBooty(Gatherer inGatherer)
{
	return;
}

function RelinquishBooty(Gatherer inGatherer)
{
	return;
}

function NotifyBeganGathering()
{
	return;
}

function NotifyEndedGathering()
{
	return;
}
