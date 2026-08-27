class TraceAmmo extends Ammunition implements IProvideTraceDamageData
	config(Weapons);

var config float TraceDistance;
var config int NumTracesToFire;
var config Rotator SpreadOfFire;
var config Vector TraceExtents;

function float GetTraceDistance()
{
	return TraceDistance;
	return;
	@NULL
}

function int GetNumTracesToFire()
{
	return NumTracesToFire;
	return;
	@NULL
}

function Rotator GetSpreadOfFire()
{
	return SpreadOfFire;
	return;
	@NULL
}

function Vector GetTraceExtents()
{
	return TraceExtents;
	return;
	@NULL
}

defaultproperties
{
	TraceDistance=99999.0000000
	NumTracesToFire=1
	DamageModel=Class'ShockGame.TraceDamageFactory'
	AttackRange=99999.0000000
}