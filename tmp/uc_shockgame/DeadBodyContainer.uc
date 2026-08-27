class DeadBodyContainer extends AnimatedContainer implements IAffectedByTelekinesis
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement);

var(Telekinesis) bool bTelekinesisDisabled;

function PostBeginPlay()
{
	super(ReactiveAnimatedMesh).PostBeginPlay();
	// End:0x26
	if(IsCensoredContent())
	{
		BurningTimeout = 1.5100000;
		return;
		@NULL
		Item
	}
	Item
}

event OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
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

// Export UDeadBodyContainer::execPreTelekinesis(FFrame&, void* const)
native event PreTelekinesis();

function bool IsAffectedByTelekinesis()
{
	// End:0x12
	if(IsCensoredContent())
	{
		return false;
		goto J0x1F;
		return __NFUN_129__(bTelekinesisDisabled);
	}
	return;
	@NULL
	Item
}

defaultproperties
{
	StartingPose=(AnimationName="None",PoseName="None",PoseRagdollState=1)
	FriendlyName="Corpse"
	bBlockActors=false
	bBlockPlayers=false
	bBlockHavok=false
	bPathColliding=false
}