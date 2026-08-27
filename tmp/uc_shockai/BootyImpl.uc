class BootyImpl extends Object
	native
	config(AI);

var private Actor Owner;
var private const Gatherer GatheringGatherer;
var private config Vector BeginGatherImpulse;
var private config Vector EndGatherImpulse;
var config array<string> UsableRigidBodies;

overloaded function Construct()
{
	assert(false);
	return;
}

function Construct(Actor inOwner)
{
	assert(__NFUN_119__(inOwner, none));
	assert(inOwner.__NFUN_303__('IBooty'));
	Owner = inOwner;
	Initialize();
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

// Export UBootyImpl::execInitialize(FFrame&, void* const)
native function Initialize();

function bool IsCurrentlyUsable(Gatherer TestGatherer)
{
	//native.TestGatherer;	
	@NULL
}

function bool GetBestGatherPoint(out Vector BestGatherPoint, out Vector BestGatherPointRigidBodyLocation, out int RigidBodyIndex)
{
	//native.BestGatherPoint;
	//native.BestGatherPointRigidBodyLocation;
	//native.RigidBodyIndex;	
	@NULL
	@NULL
	return default.@NULL;
}

function Vector GetUpdatedRigidBodyLocation(int RigidBodyIndex)
{
	//native.RigidBodyIndex;	
	@NULL
}

function Vector GetUpdatedGatherPointLocation(int RigidBodyIndex)
{
	//native.RigidBodyIndex;	
	@NULL
}

function ClaimBooty(Gatherer inGatherer)
{
	//native.inGatherer;	
	@NULL
}

function RelinquishBooty(Gatherer inGatherer)
{
	//native.inGatherer;	
	@NULL
}

// Export UBootyImpl::execNotifyBeganGathering(FFrame&, void* const)
native function NotifyBeganGathering();

// Export UBootyImpl::execNotifyEndedGathering(FFrame&, void* const)
native function NotifyEndedGathering();

defaultproperties
{
	UsableRigidBodies[0]="Ragdoll_Bip01 Pelvis01"
	UsableRigidBodies[1]="Ragdoll_Bip01 Spine03"
	UsableRigidBodies[2]="Ragdoll_Bip01 R Thigh01"
	UsableRigidBodies[3]="Ragdoll_Bip01 L Thigh01"
	UsableRigidBodies[4]="Ragdoll_Bip01 Spine02"
	UsableRigidBodies[5]="Ragdoll_Bip01 Spine01"
	UsableRigidBodies[6]="Ragdoll_Bip01 Head01"
	UsableRigidBodies[7]="Ragdoll_Bip01 Spine2"
}