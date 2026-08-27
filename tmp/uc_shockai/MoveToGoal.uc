class MoveToGoal extends BioshockMovementGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

enum EMovementType
{
	kMoveToLocation,                // 0
	kMoveToUpdatingDestination      // 1
};

var(Parameters) private MoveToGoal.EMovementType MovementType;
var(Parameters) private Actor DestinationActor;
var(Parameters) private Vector AdjustedDestinationLocation;
var(Parameters) private Vector ActualDestinationLocation;
var(Parameters) private bool bShouldNeverSucceed;
var(Parameters) private bool bShouldCutCorners;
var(Parameters) private bool bShouldModifyTravelThrottle;
var(Parameters) private float LocomotionResumeAlignmentThreshold;
var(Parameters) private float OverriddenReachedDestinationThreshold;
var(Parameters) private int AlignmentAllowedDeltaYaw;
var bool bIsTurning;
var bool bIsMoving;
var bool bCannotFindWayToDestination;
var int Dummy;
//var delegate<GetUpdatedDestination> __GetUpdatedDestination__Delegate;
//var delegate<GetDesiredFocalPointOverride> __GetDesiredFocalPointOverride__Delegate;
//var delegate<GetDesiredRotationOverride> __GetDesiredRotationOverride__Delegate;
//var delegate<GetDesiredEndRotationOverride> __GetDesiredEndRotationOverride__Delegate;
//var delegate<ShouldStopMoving> __ShouldStopMoving__Delegate;
//var delegate<OnMoveStarted> __OnMoveStarted__Delegate;
//var delegate<OnMoveEnded> __OnMoveEnded__Delegate;
//var delegate<OnTurnStarted> __OnTurnStarted__Delegate;
//var delegate<OnTurnEnded> __OnTurnEnded__Delegate;
//var delegate<OnDestinationReached> __OnDestinationReached__Delegate;
//var delegate<NotifyCannotFindWayToDestination> __NotifyCannotFindWayToDestination__Delegate;
//var delegate<NotifyFoundWayToDestination> __NotifyFoundWayToDestination__Delegate;

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	// End:0x25
	if(__NFUN_119__(DestinationActor, none))
	{
		outDestinationActor = DestinationActor;
		goto J0x38;
		outDestinationLocation = ActualDestinationLocation;
		return;
	}
	@NULL
	CommanderAction
	SpawnerBase
	@NULL
}

delegate bool GetDesiredFocalPointOverride(out Vector DesiredFocalPoint)
{
	return false;
	return;
}

delegate bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	return false;
	return;
}

delegate bool GetDesiredEndRotationOverride(out Rotator DesiredEndRotation)
{
	return false;
	return;
}

delegate bool ShouldStopMoving()
{
	return false;
	return;
}

delegate OnMoveStarted()
{
	return;
}

delegate OnMoveEnded()
{
	return;
}

delegate OnTurnStarted()
{
	return;
}

delegate OnTurnEnded()
{
	return;
}

delegate OnDestinationReached()
{
	return;
}

delegate NotifyCannotFindWayToDestination()
{
	return;
}

delegate NotifyFoundWayToDestination()
{
	return;
}

function bool IsTurning()
{
	return bIsTurning;
	return;
	@NULL
}

function bool IsMoving()
{
	return bIsMoving;
	return;
	@NULL
}

function bool CannotFindWayToDestination()
{
	return bCannotFindWayToDestination;
	return;
	@NULL
}

overloaded function Construct(AI_Resource R)
{
	assert(false);
	return;
}

function Construct(AI_Resource R, int inBehaviorPriority, Actor inDestination)
{
	construct_AI_Resource(R);
	Priority = inBehaviorPriority;
	AssertWithDescription(__NFUN_119__(inDestination, none), __NFUN_112__(__NFUN_112__("MoveToGoal was passed a Destination that is None! (AI: ", string(R.Pawn().Name)), ")"));
	DestinationActor = inDestination;
	ActualDestinationLocation = DestinationActor.Location;
	R.Pawn().GetAdjustedDestination(DestinationActor, AdjustedDestinationLocation);
	MovementType = 1;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function Construct(AI_Resource R, int inBehaviorPriority, Vector inDestination, optional bool bMoveToUpdatingDestination)
{
	construct_AI_Resource(R);
	Priority = inBehaviorPriority;
	ActualDestinationLocation = inDestination;
	AdjustedDestinationLocation = inDestination;
	R.Pawn().GetAdjustedPoint(AdjustedDestinationLocation);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x96
	/*@Error*/
	MovementType = 1;
	goto J0xA2;
	MovementType = 0;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function Actor GetDestinationActor()
{
	return DestinationActor;
	return;
	@NULL
}

function Vector GetDestinationLocation()
{
	return ActualDestinationLocation;
	return;
	@NULL
}

function bool IsMovementSatisfied(optional bool bIgnoreShouldStopMovingValue)
{
	// End:0x3A
	if(__NFUN_119__(achievingAction, none))
	{
		return MoveToAction(achievingAction).IsMovementSatisfied(bIgnoreShouldStopMovingValue);
		return false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function SetMovementType(MoveToGoal.EMovementType NewMovementType, optional Actor NewDestinationActor, optional Vector NewDestinationLocation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x285
	/*@Error*/
	MovementType = NewMovementType;
	// End:0x137
	if(__NFUN_130__(__NFUN_154__(int(NewMovementType), int(1)), __NFUN_119__(NewDestinationActor, none)))
	{
		DestinationActor = NewDestinationActor;
		ActualDestinationLocation = NewDestinationActor.Location;
		resource.Pawn().GetAdjustedDestination(DestinationActor, AdjustedDestinationLocation);
		goto J0x196;
		DestinationActor = none;
		ActualDestinationLocation = NewDestinationLocation;
		AdjustedDestinationLocation = NewDestinationLocation;
		resource.Pawn().GetAdjustedPoint(AdjustedDestinationLocation);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x285
		/*@Error*/
		MoveToAction(achievingAction).MovementType = NewMovementType;
	}
	MoveToAction(achievingAction).DestinationActor = NewDestinationActor;
	MoveToAction(achievingAction).ActualDestinationLocation = ActualDestinationLocation;
	MoveToAction(achievingAction).AdjustedDestinationLocation = AdjustedDestinationLocation;
	bCannotFindWayToDestination = false;
	achievingAction.__NFUN_113__('None');
	achievingAction.__NFUN_113__('Running');
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function SetShouldNeverSucceed(bool inShouldNeverSucceed)
{
	bShouldNeverSucceed = inShouldNeverSucceed;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4F
	/*@Error*/
	MoveToAction(achievingAction).bShouldNeverSucceed = inShouldNeverSucceed;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetOverriddenReachedDestinationThreshold(float inOverriddenReachedDestinationThreshold)
{
	OverriddenReachedDestinationThreshold = inOverriddenReachedDestinationThreshold;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4B
	/*@Error*/
	MoveToAction(achievingAction).super(MoveToGoal).SetOverriddenReachedDestinationThreshold(inOverriddenReachedDestinationThreshold);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ClearOverriddenReachedDestinationThreshold()
{
	// End:0x2F
	if(__NFUN_119__(achievingAction, none))
	{
		MoveToAction(achievingAction).super(MoveToGoal).ClearOverriddenReachedDestinationThreshold();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function SetShouldCutCorners(bool inShouldCutCorners)
{
	bShouldCutCorners = inShouldCutCorners;
	return;
	@NULL
	CommanderAction
}

function SetShouldModifyTravelThrottle(bool inShouldModifyTravelThrottle)
{
	bShouldModifyTravelThrottle = inShouldModifyTravelThrottle;
	return;
	@NULL
	CommanderAction
}

function SetLocomotionResumeAlignmentThreshold(float inLocomotionResumeAlignmentThreshold)
{
	LocomotionResumeAlignmentThreshold = inLocomotionResumeAlignmentThreshold;
	return;
	@NULL
	CommanderAction
}

function SetAlignmentAllowedDeltaYaw(int inAlignmentAllowedDeltaYaw)
{
	AlignmentAllowedDeltaYaw = inAlignmentAllowedDeltaYaw;
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	bShouldModifyTravelThrottle=true
	LocomotionResumeAlignmentThreshold=0.9000000
	bTryOnlyOnce=true
	Priority=0
}