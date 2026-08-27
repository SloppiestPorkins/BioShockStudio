class SecurityCameraDeadBody extends StaticMeshContainer implements IAffectedByTelekinesis
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement);

event OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
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

function InitializeFromLiveBody(Container inContainer)
{
	Container = inContainer;
	// End:0x3A
	if(__NFUN_119__(Container, none))
	{
		Container.SetOwner(self);
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

defaultproperties
{
	FriendlyName="Destroyed Security Camera"
	Physics=1
	StaticMesh=StaticMesh'ShockAI.FX_sm.SmCamWallPitch'
	CollisionRadius=75.0000000
	CollisionHeight=130.0000000
	bBlockActors=false
	bBlockPlayers=false
}