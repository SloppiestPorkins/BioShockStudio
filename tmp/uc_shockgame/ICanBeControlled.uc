interface ICanBeControlled
	native
	parseconfig;

function OnRegistered(ShockPawn Registerer)
{
	return;
}

function OnUnregistered(ShockPawn Registerer)
{
	return;
}

function OnControllerKilled(ShockPawn Controller)
{
	return;
}

function OnControllerDestroyed(ShockPawn Controller)
{
	return;
}

function OnControllerDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	return;
}

function OnControllerDealtDamage(ShockPawn Damagee, float TotalDamageDealt)
{
	return;
}

function AttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{
	return;
}

function SetSector(int Sector)
{
	return;
}

function int GetSector()
{
	return;
}
