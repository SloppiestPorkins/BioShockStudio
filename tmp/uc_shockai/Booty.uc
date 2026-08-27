class Booty extends ReactiveAnimatedMesh implements IBooty, IHaveAContainer, IAffectedByTelekinesis
	abstract
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure);

var private BootyImpl BootyImpl;
var private NavigationPoint ClosestNavigationPoint;
var private export editinline Container Container;
var(Telekinesis) bool bTelekinesisDisabled;

function PreBeginPlay()
{
	super.PreBeginPlay();
	// End:0x31
	if(__NFUN_119__(Container, none))
	{
		Container.SetOwner(self);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x73
		/*@Error*/
	}
	StartingPose.PoseRagdollState = 1;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PostBeginPlay()
{
	super.PostBeginPlay();
	GetRagdoll().SetRisePoseMatchingEnabled(false);
	BootyImpl = Class'ShockAI.BootyImpl'.static.Allocate(self).;
	construct_Actor(self);
	// End:0x6E
	if(__NFUN_114__(ClosestNavigationPoint, none))
	{
		FindClosestNavigationPoint();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x8A
		/*@Error*/
		BurningTimeout = 1.5100000;
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FindClosestNavigationPoint()
{
	local NavigationPoint Iter, Closest;
	local float IterDistance, ClosestDistance;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x121
	/*@Error*/
	Iter = Level.NavigationPointList[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x113
	/*@Error*/
	IterDistance = __NFUN_225__(__NFUN_216__(Iter.Location, Location));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x113
	/*@Error*/
	Closest = Iter;
	ClosestDistance = IterDistance;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	ClosestNavigationPoint = Closest;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsUsableAsBooty(Gatherer TestGatherer)
{
	return __NFUN_130__(__NFUN_119__(BootyImpl, none), BootyImpl.IsCurrentlyUsable(TestGatherer));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NavigationPoint GetClosestNavigationPoint()
{
	return ClosestNavigationPoint;
	return;
	@NULL
}

function bool GetBestGatherPoint(out Vector BestGatherPoint, out Vector BestGatherPointRigidBodyLocation, out int RigidBodyIndex)
{
	assert(__NFUN_119__(BootyImpl, none));
	return BootyImpl.GetBestGatherPoint(BestGatherPoint, BestGatherPointRigidBodyLocation, RigidBodyIndex);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Vector GetUpdatedRigidBodyLocation(int RigidBodyIndex)
{
	assert(__NFUN_119__(BootyImpl, none));
	return BootyImpl.GetUpdatedRigidBodyLocation(RigidBodyIndex);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Vector GetUpdatedGatherPointLocation(int RigidBodyIndex)
{
	assert(__NFUN_119__(BootyImpl, none));
	return BootyImpl.GetUpdatedGatherPointLocation(RigidBodyIndex);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function ClaimBooty(Gatherer inGatherer)
{
	assert(__NFUN_119__(BootyImpl, none));
	BootyImpl.ClaimBooty(inGatherer);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function RelinquishBooty(Gatherer inGatherer)
{
	assert(__NFUN_119__(BootyImpl, none));
	BootyImpl.RelinquishBooty(inGatherer);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyBeganGathering()
{
	assert(__NFUN_119__(BootyImpl, none));
	BootyImpl.NotifyBeganGathering();
	return;
	@NULL
	CommanderAction
}

function NotifyEndedGathering()
{
	assert(__NFUN_119__(BootyImpl, none));
	BootyImpl.NotifyEndedGathering();
	return;
	@NULL
	CommanderAction
}

function ZoneChange(ZoneInfo NewZone)
{
	SpawningManager(Level.SpawningManager).UpdateBootyZone(self, NewZone);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function Container GetContainer()
{
	return Container;
	return;
	@NULL
}

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(thePlayer.CanUseContainer(Container), bShowHudElements);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	super(ReactiveActor).OnUsed(Pawn);
	ShockPlayer(Pawn).OpenContainer(Container, GetCurrentMaterial());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	local string feedbackString;

	feedbackString = GetFocusDisplayName();
	// End:0x41
	if(CanBeUsedNow())
	{
		Container.ModifyHudMessage(feedbackString);
		return feedbackString;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
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

// Export UBooty::execPreTelekinesis(FFrame&, void* const)
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
	CommanderAction
}

defaultproperties
{
	bPlayOnStartup=false
	StartingPose=(AnimationName="None",PoseName="None",PoseRagdollState=1)
	FriendlyName="Corpse"
	UseVerbText="SEARCH"
	bNoDelete=true
	CollisionRadius=16.0000000
	CollisionHeight=20.0000000
	bCollideWorld=true
	bBlockActors=false
	bBlockPlayers=false
	bPathColliding=false
}