class SearchGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private ShockPawn SearchTarget;
var(Parameters) private Vector LastKnownLocation;
var(Parameters) private Vector LastMovingDirection;
var(Parameters) private Vector LocationWhenLostTarget;
var(Parameters) private Actor AnchorActor;
var(Parameters) private float MaxDistanceFromAnchor;
var(Parameters) private int AlignmentAllowedDeltaYaw;
var(Parameters) private bool NeverStopSearching;

function Construct(AI_Resource R, ShockPawn inSearchTarget, Vector inLastKnownLocation, Vector inLastMovingDirection, Vector inLocationWhenLostTarget)
{
	construct_AI_Resource(R);
	assert(__NFUN_119__(inSearchTarget, none));
	SearchTarget = inSearchTarget;
	LastKnownLocation = inLastKnownLocation;
	LastMovingDirection = inLastMovingDirection;
	LocationWhenLostTarget = inLocationWhenLostTarget;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function SetMaximumDistanceToMoveFromActor(Actor inAnchorActor, float inMaxDistanceFromAnchor)
{
	assert(__NFUN_119__(inAnchorActor, none));
	assert(__NFUN_179__(inMaxDistanceFromAnchor, 0.0000000));
	AnchorActor = inAnchorActor;
	MaxDistanceFromAnchor = inMaxDistanceFromAnchor;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetAlignmentAllowedDeltaYaw(int inAlignmentAllowedDeltaYaw)
{
	AlignmentAllowedDeltaYaw = inAlignmentAllowedDeltaYaw;
	return;
	@NULL
	CommanderAction
}

function SetNeverStopSearching(bool inNeverStopSearching)
{
	NeverStopSearching = inNeverStopSearching;
	return;
	@NULL
	CommanderAction
}

function UpdateSuspiciousLocation(Vector SuspiciousLocation, Vector SuspiciousTargetVelocity)
{
	// End:0x44
	if(__NFUN_119__(achievingAction, none))
	{
		SearchAction(achievingAction).UpdateSuspiciousLocation(SuspiciousLocation, SuspiciousTargetVelocity);
		goto J0x98;
		LastKnownLocation = SuspiciousLocation;
		LastMovingDirection = SuspiciousTargetVelocity;
	}
	LocationWhenLostTarget = resource.Pawn().Location;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ShockPawn GetSearchTarget()
{
	return SearchTarget;
	return;
	@NULL
}

defaultproperties
{
	bTryOnlyOnce=true
	Priority=70
}