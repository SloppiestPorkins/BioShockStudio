class PhysicalStaticMeshContainer extends StaticMeshContainer implements IAffectedByTelekinesis
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement,Collision);

function OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
{
	return;
}

event Actor GetAffectedActor()
{
	return self;
	return;
}

function PreTelekinesis()
{
	return;
}

function bool IsAffectedByTelekinesis()
{
	return true;
	return;
}

defaultproperties
{
	Physics=1
	bBlockActors=false
	bBlockPlayers=false
	bPathColliding=false
}