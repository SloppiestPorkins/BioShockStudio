class ReactToAlertGathererAction extends BioshockCharacterAction implements IInterestedActorDestroyed, IInterestedPawnDied
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

enum EAlertReactionState
{
	kHungry,                        // 0
	kAggressive,                    // 1
	kMovingAway,                    // 2
	kCannotMoveAway                 // 3
};

var(Parameters) Gatherer AlertGatherer;
var(Parameters) Protector ThreateningProtector;
var private MoveToGoal CurrentMoveToGoal;
var private ReactToAlertGathererAction.EAlertReactionState AlertReactionState;
var private Actor PointToMoveTo;
var private bool bGathererNoLongerAlerted;
var private Rotator OppositeMovingDirection;
var private float TimeOutTime;
var config float DesiredDistanceFromGatherer;
var config float MinDistanceToApproachGatherer;
var config Range TimeBeforeTimingOutRange;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	m_Pawn.Level.RegisterNotifyPawnDied(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		ShockAI().SetAvoidTarget(none);
	}
	ShockAI().AddLocomotionKeyword('Hungry', Class'ShockAI.ShockAI'.-1);
	m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	m_Pawn.Level.UnRegisterNotifyPawnDied(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	// End:0x3A
	if(__NFUN_132__(__NFUN_114__(DeadPawn, AlertGatherer), __NFUN_114__(DeadPawn, ThreateningProtector)))
	{
		instantSucceed();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	// End:0x3A
	if(__NFUN_132__(__NFUN_114__(ActorBeingDestroyed, AlertGatherer), __NFUN_114__(ActorBeingDestroyed, ThreateningProtector)))
	{
		instantSucceed();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().AddLocomotionKeyword('Hungry', 1);
	ShockAI().BecomeAggressive();
	ShockAI().SetShouldRun();
	return;
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	ShockAI().AddLocomotionKeyword('Hungry', Class'ShockAI.ShockAI'.-1);
	return;
	@NULL
	CommanderAction
}

function NotifyProtectorThreatening(Protector ThreateningProtector)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x20
	/*@Error*/
	AlertReactionState = 1;
	return;
	@NULL
	CommanderAction
}

function NotifyKnockedBackByThreateningProtector(Protector ThreateningProtector)
{
	AlertReactionState = 2;
	return;
	@NULL
}

function NotifyCausedGathererAlert(Gatherer NewAlertGatherer, Protector NewThreateningProtector)
{
	// End:0x23
	if(__NFUN_114__(AlertGatherer, NewAlertGatherer))
	{
		bGathererNoLongerAlerted = false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function NotifyGathererAlertOver(Gatherer FormerAlertGatherer, Protector FormerThreateningProtector)
{
	bGathererNoLongerAlerted = true;
	return;
	@NULL
}

function bool CanSeeGathererOrProtector()
{
	return __NFUN_132__(m_Pawn.CanSee(ThreateningProtector), m_Pawn.CanSee(AlertGatherer));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsCloseToGatherer()
{
	return IsPointWithinCylinder(m_Pawn.Location, AlertGatherer.Location, Class'ShockAI.GathererCommanderAction'.default.AlertedDistanceRange.Max, __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldKeepAwayFromProtectorAndGatherer()
{
	return __NFUN_130__(__NFUN_176__(__NFUN_175__(Level().TimeSeconds, m_Pawn.LastRenderTime), 10.0000000), __NFUN_132__(IsCloseToGatherer(), CanSeeGathererOrProtector()));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function bool GetRotationToTarget(out Rotator DesiredRotation)
{
	// End:0x51
	if(__NFUN_154__(int(AlertReactionState), int(0)))
	{
		DesiredRotation = Rotator(__NFUN_216__(AlertGatherer.Location, m_Pawn.Location));
		goto J0x8B;
		DesiredRotation = Rotator(__NFUN_216__(ThreateningProtector.Location, m_Pawn.Location));
	}
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FaceTarget()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToTarget;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = None;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetRotationWhileMovingToPoint(out Rotator DesiredRotation)
{
	local Vector OffsetToProtector;

	// End:0x90
	if(CurrentMoveToGoal.IsMoving())
	{
		OffsetToProtector = __NFUN_216__(ThreateningProtector.Location, m_Pawn.Location);
		// End:0x8D
		if(m_Pawn.LineOfSightTo(ThreateningProtector, true))
		{
			DesiredRotation = Rotator(OffsetToProtector);
			return true;
			goto J0x167;
			// End:0xF1
			if(m_Pawn.LineOfSightTo(ThreateningProtector, true))
			{
				DesiredRotation = Rotator(__NFUN_216__(ThreateningProtector.Location, m_Pawn.Location));
			}
		}
		goto J0x165;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x152
		/*@Error*/
		DesiredRotation = Rotator(__NFUN_216__(AlertGatherer.Location, m_Pawn.Location));
		goto J0x165;
	}
	DesiredRotation = OppositeMovingDirection;
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnMoveEnded()
{
	OppositeMovingDirection = Rotator(__NFUN_211__(ShockAI().GetAverageVelocity()));
	return;
	@NULL
	CommanderAction
}

function MoveToPoint()
{
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	ShockAI().SetShouldWalk();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationWhileMovingToPoint;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.SetMovementType(1, PointToMoveTo);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBB
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0x89;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function MoveAwayFromGatherer()
{
	ShockAI().SetAvoidTarget(ThreateningProtector);
	// End:0x7E
	if(ShockAI().FindPointToAvoidTarget(ThreateningProtector, PointToMoveTo, false, DesiredDistanceFromGatherer,,,, true, MinDistanceToApproachGatherer))
	{
		MoveToPoint();
		AlertReactionState = 1;
		goto J0xE3;
		log(,, __NFUN_112__(string(m_Pawn.Name), " could not find a point to move away from the gatherer"));
	}
	AlertReactionState = 3;
	ShockAI().SetAvoidTarget(none);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	useResources(Class'VengeanceShared.AI_Resource'.2);
	ShockAI().SetShouldRun();
	ShockAI().BecomeAggressive();
	ShockAI().AddLocomotionKeyword('Hungry', 1);
	FaceTarget();
	// End:0x96
	if(__NFUN_154__(int(AlertReactionState), int(0)))
	{
		yield();
		// [Loop Continue]
		goto J0x75;
		ShockAI().BecomeAggressive();
	}
	// End:0xE0
	if(__NFUN_130__(__NFUN_155__(int(AlertReactionState), int(2)), __NFUN_129__(bGathererNoLongerAlerted)))
	{
		yield();
		// [Loop Continue]
		goto J0xAE;
		// End:0xFE
		if(__NFUN_154__(int(AlertReactionState), int(2)))
		{
		}
		MoveAwayFromGatherer();
		// End:0x148
		if(__NFUN_154__(int(AlertReactionState), int(3)))
		{
			EcologyFighter(m_Pawn).AddForcedEnemy(ThreateningProtector);
		}
		succeed();
		goto J0x271;
		// End:0x164
		if(ShouldKeepAwayFromProtectorAndGatherer())
		{
			AlertReactionState = 2;
			goto J0x271;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x271
			/*@Error*/
			TimeOutTime = __NFUN_174__(Level().TimeSeconds, RandRange(TimeBeforeTimingOutRange.Min, TimeBeforeTimingOutRange.Max));
		}
	}
	// End:0x222
	if(__NFUN_130__(__NFUN_130__(bGathererNoLongerAlerted, __NFUN_176__(Level().TimeSeconds, TimeOutTime)), __NFUN_129__(ShouldKeepAwayFromProtectorAndGatherer())))
	{
		__NFUN_256__(0.5000000);
		goto J0x1D2;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x271
		/*@Error*/
		succeed();
		yield();
		goto 'Aggressive';
		stop;				
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	DesiredDistanceFromGatherer=1000.0000000
	MinDistanceToApproachGatherer=300.0000000
	TimeBeforeTimingOutRange=(Min=25.0000000,Max=40.0000000)
	satisfiesGoal=Class'ShockAI.ReactToAlertGathererGoal'
	bExclusiveAction=true
}