class TraceAttackAbility extends AttackAbility implements IProvideTraceDamageData
	abstract
	config(Abilities);

var config float AttackRange;
var config float TraceDistance;
var config int NumTracesToFire;
var config Rotator SpreadOfFire;
var config Vector TraceExtents;

function float GetAttackRange()
{
	return AttackRange;
	return;
	@NULL
}

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
	AttackRange=99999.0000000
	TraceDistance=99999.0000000
	NumTracesToFire=1
	MagicBulletRadius=0.1000000
	MagicBulletChance=1.0000000
}