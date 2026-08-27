class MoveToAction extends BioshockMovementAction implements ILocomotionListener, IInterestedActorDestroyed
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

const kMinTimeToRetryPathfindingAfterFailure = 0.5;
const kMinTimeToAvoidCollisions = 0.2f;
const LookAheadDistance = 100.0f;
const kTimeForDestinationDoorToBeRenderedToForceNormalLOD = 3.0;
const kTimeToOverrideLowLOD = 5.0;

var(Parameters) MoveToGoal.EMovementType MovementType;
var(Parameters) Actor DestinationActor;
var(Parameters) Vector AdjustedDestinationLocation;
var(Parameters) Vector ActualDestinationLocation;
var(Parameters) bool bShouldNeverSucceed;
var(Parameters) bool bShouldCutCorners;
var(Parameters) private bool bShouldModifyTravelThrottle;
var(Parameters) private float LocomotionResumeAlignmentThreshold;
var(Parameters) private float OverriddenReachedDestinationThreshold;
var(Parameters) private int AlignmentAllowedDeltaYaw;
var private MoveToGoal AchievingMoveToGoal;
var private JumpToCeilingGoal CurrentJumpToCeilingGoal;
var private JumpToFloorGoal CurrentJumpToFloorGoal;
var private bool bNotifiedMoveStarted;
var private bool bNotifiedTurnStarted;
var private const float LastUpdatedDestinationUpdateTime;
var private const bool LastUpdatedDestinationUpdateValue;
var private const float LastDesiredFocalPointOverrideUpdateTime;
var private const bool LastDesiredFocalPointOverrideUpdateValue;
var private const Vector LastDesiredFocalPointOverrideUpdateVector;
var private const float LastDesiredRotationOverrideUpdateTime;
var private const bool LastDesiredRotationOverrideUpdateValue;
var private const Rotator LastDesiredRotationOverrideUpdateRotation;
var private const float LastDesiredEndRotationOverrideUpdateTime;
var private const bool LastDesiredEndRotationOverrideUpdateValue;
var private const Rotator LastDesiredEndRotationOverrideUpdateRotation;
var private const float MoveTimer;
var private float PathfindingTimeoutEndTime;
var private const float CollisionAvoidanceEndTime;
var private const bool bReEvaluateCurveWhenCloseToPathDestination;
var const array<Vector> SmoothedPath;
var private const float AccumulatedDeltaSeconds;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_Action).initAction(R, Goal);
	assert(__NFUN_119__(m_Pawn, none));
	AchievingMoveToGoal = MoveToGoal(Goal);
	assert(__NFUN_119__(AchievingMoveToGoal, none));
	AchievingMoveToGoal.__NFUN_199__();
	SetOverriddenReachedDestinationThreshold(OverriddenReachedDestinationThreshold);
	SetupLocomotion();
	ShockAI(m_Pawn).bIsAvoiding = false;
	ShockAI(m_Pawn).AvoidanceStartDistance = 1000000000.0000000;
	ShockAI(m_Pawn).SetLocomotionResumeAlignmentThreshold(LocomotionResumeAlignmentThreshold);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(ActionBase).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentJumpToCeilingGoal, none))
	{
		CurrentJumpToCeilingGoal.__NFUN_198__();
		CurrentJumpToCeilingGoal = none;
		// End:0x5C
		if(__NFUN_119__(CurrentJumpToFloorGoal, none))
		{
			CurrentJumpToFloorGoal.__NFUN_198__();
		}
		CurrentJumpToFloorGoal = none;
		CleanupLocomotion();
		ShockAI().SetLocomotionResumeAlignmentThreshold(ShockAI().GetDefaultLocomotionResumeAlignmentThreshold());
	}
	// End:0x109
	if(__NFUN_151__(m_Pawn.Controller.PathList.Length, 0))
	{
		m_Pawn.Controller.PathList.Remove(0, m_Pawn.Controller.PathList.Length);
		m_Pawn.Acceleration = vect(0.0000000, 0.0000000, 0.0000000);
		m_Pawn.Velocity = vect(0.0000000, 0.0000000, 0.0000000);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x22C
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22C
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22C
	/*@Error*/
	m_Pawn.bNoPawnCollision = false;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x255
	/*@Error*/
	AchievingMoveToGoal.__NFUN_198__();
	AchievingMoveToGoal = none;
	ClearOverriddenReachedDestinationThreshold();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xBF
	/*@Error*/
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn), " succeeding "), string(Name)), " due to DestinationActor ("), string(DestinationActor)), ") being destroyed.  Parent Action is: "), string(achievingGoal.parentAction)));
	instantSucceed();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UMoveToAction::execSetupLocomotion(FFrame&, void* const)
native final function SetupLocomotion();

// Export UMoveToAction::execCleanupLocomotion(FFrame&, void* const)
native final function CleanupLocomotion();

function OnLocomotionMovementRequestCompleted(Vector RequestLocationWorldSpace)
{
	//native.RequestLocationWorldSpace;	
	@NULL
}

function OnWalkCycleLooped()
{
	return;
}

// Export UMoveToAction::execStopLocomotion(FFrame&, void* const)
native final function StopLocomotion();

// Export UMoveToAction::execStopMoving(FFrame&, void* const)
native final function StopMoving();

function SendStopLocomotionRequest(VPawn Pawn)
{
	//native.Pawn;	
	@NULL
}

function string DebugDestination()
{
	local string DebugDestinationInfo;

	// End:0x85
	if(__NFUN_119__(DestinationActor, none))
	{
		DebugDestinationInfo = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Actor: ", string(DestinationActor)), " (Current Position: "), string(DestinationActor.Location)), " Adjusted: "), string(AdjustedDestinationLocation)), ")");
		goto J0xCB;
		DebugDestinationInfo = __NFUN_112__(__NFUN_112__(__NFUN_112__("Actual Location: ", string(ActualDestinationLocation)), " Adjusted: "), string(AdjustedDestinationLocation));
	}
	return DebugDestinationInfo;
	return;
	@NULL
	EcologyCommanderAction
	stop;
	return @NULL;
}

function string DebugPathList()
{
	local string DebugPathListInfo;
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xF3
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF0
	/*@Error*/
	// End:0x91
	if(__NFUN_155__(i, 0))
	{
		DebugPathListInfo = __NFUN_112__(DebugPathListInfo, " -> ");
		DebugPathListInfo = __NFUN_112__(DebugPathListInfo, string(m_Pawn.Controller.PathList[i].Name));
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x35;
	goto J0x10F;
	DebugPathListInfo = "Path List Empty!";
	return DebugPathListInfo;
	return;
	@NULL
	EcologyCommanderAction
	stop;
	return @NULL;
}

function bool IsMovementSatisfied(optional bool bIgnoreShouldStopMovingValue)
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(AchievingMoveToGoal.IsMoving()), __NFUN_129__(AchievingMoveToGoal.IsTurning())), __NFUN_132__(HasReachedDesiredDestination(), __NFUN_130__(__NFUN_129__(bIgnoreShouldStopMovingValue), AchievingMoveToGoal.ShouldStopMoving()))), IsRotatedToDesiredDirection());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UMoveToAction::execMoveAlongPath(FFrame&, void* const)
private native final latent function MoveAlongPath();

// Export UMoveToAction::execMoveToDesiredDestination(FFrame&, void* const)
private native final latent function MoveToDesiredDestination();

// Export UMoveToAction::execUpdateDestination(FFrame&, void* const)
private native function bool UpdateDestination();

// Export UMoveToAction::execHasReachedDesiredDestination(FFrame&, void* const)
native final function bool HasReachedDesiredDestination();

function SetOverriddenReachedDestinationThreshold(float inOverriddenReachedDestinationThreshold)
{
	//native.inOverriddenReachedDestinationThreshold;	
	@NULL
}

// Export UMoveToAction::execClearOverriddenReachedDestinationThreshold(FFrame&, void* const)
native final function ClearOverriddenReachedDestinationThreshold();

// Export UMoveToAction::execCanReachDesiredDestination(FFrame&, void* const)
native final function bool CanReachDesiredDestination();

// Export UMoveToAction::execFindPathToDesiredDestination(FFrame&, void* const)
native final function bool FindPathToDesiredDestination();

// Export UMoveToAction::execShouldFindNewPathToDesiredDestination(FFrame&, void* const)
native final function bool ShouldFindNewPathToDesiredDestination();

// Export UMoveToAction::execShouldPauseBeforePathfinding(FFrame&, void* const)
native final function bool ShouldPauseBeforePathfinding();

function bool IsRotatedTo(Rotator CurrentRotation, Rotator DesiredRotation, optional int AllowedYawRotationError)
{
	//native.CurrentRotation;
	//native.DesiredRotation;
	//native.AllowedYawRotationError;	
	@NULL
	BioshockCharacterAction
	2
}

// Export UMoveToAction::execIsRotatedToDesiredDirection(FFrame&, void* const)
native final function bool IsRotatedToDesiredDirection();

// Export UMoveToAction::execUpdateRotation(FFrame&, void* const)
native final function UpdateRotation();

function PrepareForMove()
{
	local NavigationPoint Anchor;

	J0x00:
	// End:0x2E [Loop If]
	if(__NFUN_154__(int(m_Pawn.Physics), int(4)))
	{
		yield();
		// [Loop Continue]
		goto J0x00;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xBE
		/*@Error*/
	}
	Anchor = m_Pawn.GetAnchor();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBE
	/*@Error*/
	JumpToFloor();
	return;
	@NULL
	BotBaseAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	// End:0x31
	if(__NFUN_129__(ShockAI().IsFrozen()))
	{
		StopMoving();
		ClearOverriddenReachedDestinationThreshold();
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyRunningDueToExclusivity()
{
	NotifyPausedDueToExclusivity();
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " with parent action "), string(achievingGoal.parentAction)), " restarting movement behavior."));
	SetOverriddenReachedDestinationThreshold(OverriddenReachedDestinationThreshold);
	m_Pawn.Controller.PathList.Remove(0, m_Pawn.Controller.PathList.Length);
	SmoothedPath.Remove(0, SmoothedPath.Length);
	__NFUN_113__('None');
	__NFUN_113__('Running');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PrepareForMoveTo(Actor NextDestinationActor, Vector NextDestinationLocation)
{
	local NavigationPoint NextDestinationNavigationPoint;
	local CeilingPatrolPoint NextDestinationCeilingPatrolPoint;
	local CeilingPathNode NextDestinationCeilingPathNode;
	local FloorPoint NextDestinationFloorPoint;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x328
	/*@Error*/
	NextDestinationNavigationPoint = NavigationPoint(NextDestinationActor);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x328
	/*@Error*/
	// End:0x23C
	if(__NFUN_129__(m_Pawn.IsOnCeiling()))
	{
		NextDestinationCeilingPathNode = CeilingPathNode(NextDestinationNavigationPoint);
		// End:0x14D
		if(__NFUN_130__(__NFUN_119__(NextDestinationCeilingPathNode, none), m_Pawn.ReachedDestination(NextDestinationCeilingPathNode.ConnectedFloorPoint)))
		{
			JumpToCeiling();
			// End:0x14D
			if(__NFUN_130__(__NFUN_151__(m_Pawn.Controller.PathList.Length, 0), __NFUN_114__(m_Pawn.Controller.PathList[0], NextDestinationNavigationPoint)))
			{
				m_Pawn.Controller.PathList.Remove(0, 1);
				NextDestinationCeilingPatrolPoint = CeilingPatrolPoint(NextDestinationNavigationPoint);
				// End:0x239
				if(__NFUN_130__(__NFUN_119__(NextDestinationCeilingPatrolPoint, none), m_Pawn.ReachedDestination(NextDestinationCeilingPatrolPoint.ConnectedFloorPoint)))
				{
					JumpToCeiling();
					// End:0x239
					if(__NFUN_130__(__NFUN_151__(m_Pawn.Controller.PathList.Length, 0), __NFUN_114__(m_Pawn.Controller.PathList[0], NextDestinationNavigationPoint)))
					{
					}
				}
				m_Pawn.Controller.PathList.Remove(0, 1);
				goto J0x328;
				NextDestinationFloorPoint = FloorPoint(NextDestinationNavigationPoint);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x328
				/*@Error*/
				JumpToFloor();
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x328
				/*@Error*/
				m_Pawn.Controller.PathList.Remove(0, 1);
			}
		}
	}
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function JumpToCeiling()
{
	assert(__NFUN_129__(m_Pawn.IsOnCeiling()));
	// End:0x77
	if(__NFUN_119__(CurrentJumpToCeilingGoal, none))
	{
		assert(CurrentJumpToCeilingGoal.hasCompleted());
		CurrentJumpToCeilingGoal.unPostGoal(self);
		CurrentJumpToCeilingGoal.__NFUN_198__();
		CurrentJumpToCeilingGoal = none;
		assert(__NFUN_114__(CurrentJumpToCeilingGoal, none));
		CurrentJumpToCeilingGoal = Class'ShockAI.JumpToCeilingGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceIntVector(characterResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentJumpToCeilingGoal.__NFUN_199__();
	CurrentJumpToCeilingGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentJumpToCeilingGoal);
	CurrentJumpToCeilingGoal.unPostGoal(self);
	CurrentJumpToCeilingGoal.__NFUN_198__();
	CurrentJumpToCeilingGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function JumpToFloor()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x157
	/*@Error*/
	// End:0x75
	if(__NFUN_119__(CurrentJumpToFloorGoal, none))
	{
		assert(CurrentJumpToFloorGoal.hasCompleted());
		CurrentJumpToFloorGoal.unPostGoal(self);
		CurrentJumpToFloorGoal.__NFUN_198__();
		CurrentJumpToFloorGoal = none;
		assert(__NFUN_114__(CurrentJumpToFloorGoal, none));
		CurrentJumpToFloorGoal = Class'ShockAI.JumpToFloorGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceIntVector(characterResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentJumpToFloorGoal.__NFUN_199__();
	CurrentJumpToFloorGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentJumpToFloorGoal);
	CurrentJumpToFloorGoal.unPostGoal(self);
	CurrentJumpToFloorGoal.__NFUN_198__();
	CurrentJumpToFloorGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0xD0
	if(__NFUN_153__(int(GetLogLOD('Pathfinding')), 4))
	{
		log('Pathfinding', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " began moving to "), DebugDestination()), " HasReachedDesiredDestination: "), string(HasReachedDesiredDestination())), " ShouldStopMoving: "), string(AchievingMoveToGoal.ShouldStopMoving())));
		// End:0x673
		if(__NFUN_130__(__NFUN_129__(AchievingMoveToGoal.ShouldStopMoving()), __NFUN_129__(HasReachedDesiredDestination())))
		{
		}
		PrepareForMove();
		// End:0x162
		if(__NFUN_129__(bNotifiedMoveStarted))
		{
			bNotifiedMoveStarted = true;
			AchievingMoveToGoal.bIsMoving = true;
			AchievingMoveToGoal.OnMoveStarted();
			// End:0x266
			if(CanReachDesiredDestination())
			{
				log('Pathfinding', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " destination "), DebugDestination()), " is reachable, moving directly to it"));
			}
			// End:0x22E
			if(AchievingMoveToGoal.bCannotFindWayToDestination)
			{
				AchievingMoveToGoal.bCannotFindWayToDestination = false;
				AchievingMoveToGoal.NotifyFoundWayToDestination();
				// End:0x259
				if(__NFUN_119__(DestinationActor, none))
				{
					PrepareForMoveTo(DestinationActor, AdjustedDestinationLocation);
					MoveToDesiredDestination();
					goto J0x670;
					// End:0x57F
					if(ShouldFindNewPathToDesiredDestination())
					{
						// End:0x392
						if(ShouldPauseBeforePathfinding())
						{
							log('Pathfinding', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " going to wait at time "), string(Level().TimeSeconds)), " until "), string(__NFUN_174__(0.5000000, ShockAI().LastPathfindingFailedTime))), " (or the destination changes) before building a path to "), DebugDestination()), " CannotFindWayToDestination: "), string(AchievingMoveToGoal.CannotFindWayToDestination())));
						}
					}
				}
				goto J0x673;
				log('Pathfinding', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " going to look for a path to "), DebugDestination()));
				// End:0x52D
				if(__NFUN_129__(FindPathToDesiredDestination()))
				{
					log('Pathfinding', 2, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " could not find path to "), DebugDestination()));
					// End:0x4D7
					if(ShockGameInfo(Level().Game).bDisplayDebugInfoOnAIs)
					{
					}
					m_Pawn.AddDebugMessage(__NFUN_112__("Could not find path to ", DebugDestination()), 5.0000000, Class'Engine.Canvas'.static.MakeColor(byte(255), 225, 225));
					AchievingMoveToGoal.bCannotFindWayToDestination = true;
					AchievingMoveToGoal.NotifyCannotFindWayToDestination();
					// End:0x52A
					if(__NFUN_129__(bShouldNeverSucceed))
					{
						fail(4);
						goto J0x57F;
						// End:0x57F
						if(AchievingMoveToGoal.bCannotFindWayToDestination)
						{
							AchievingMoveToGoal.bCannotFindWayToDestination = false;
							AchievingMoveToGoal.NotifyFoundWayToDestination();
							// End:0x66D
							if(__NFUN_129__(AchievingMoveToGoal.bCannotFindWayToDestination))
							{
								log('Pathfinding', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " will move using path ("), DebugPathList()), ") to "), DebugDestination()));
							}
							PrepareForMoveTo(m_Pawn.Controller.PathList[0], m_Pawn.Controller.PathList[0].Location);
						}
						MoveAlongPath();
					}
					goto J0x670;
					goto J0x673;
					// [Loop Continue]
					goto J0xD0;
					// End:0x6CE
					if(bNotifiedMoveStarted)
					{
						bNotifiedMoveStarted = false;
						StopMoving();
						AchievingMoveToGoal.bIsMoving = false;
						AchievingMoveToGoal.OnMoveEnded();
						bNotifiedTurnStarted = false;
					}
				}
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x7B3
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x79C
				/*@Error*/
				bNotifiedTurnStarted = true;
				AchievingMoveToGoal.bIsTurning = true;
				AchievingMoveToGoal.OnTurnStarted();
				UpdateRotation();
				yield();
				goto J0x6DA;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x7F8
				/*@Error*/
				AchievingMoveToGoal.bIsTurning = false;
				AchievingMoveToGoal.OnTurnEnded();
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x8B5
				/*@Error*/
				log('Pathfinding', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " will never succeed in its movement behavior, starting over when we should start moving again to "), DebugDestination()));
			}
		}
	}
	yield();
	goto 'Begin';
	goto J0x8BF;
	succeed();
	stop;				
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.MoveToGoal'
}