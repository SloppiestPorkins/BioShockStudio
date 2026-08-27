class DouseAction extends BioshockCharacterAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AvoidTarget;
var(Parameters) NavigationPoint PointInWater;
var private MoveToGoal CurrentMoveToGoal;
var private float JumpInWaterAnimationTranslationSize;
var private Vector JumpInWaterDestination;
var private bool bMovingToJumpIntoWater;
var private int JumpInWaterAnimationHandle;
var private name JumpInWaterAnimation;
var private float JumpInWaterAnimLength;
var private Vector LastRootPosition;
var private float LastRootPositionUpdateTime;
var private config float MinApproachDistanceToAttackTarget;
var private config float MinDistanceToTarget;
var private config float MinDesiredDistanceToMove;
var private config int JumpIntoWaterAllowedAlignmentDeltaYaw;

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
	// End:0x8F
	if(m_Pawn.IsAnimationHandleValid(JumpInWaterAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(JumpInWaterAnimationHandle);
		m_Pawn.__NFUN_3970__(2);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x119
		/*@Error*/
	}
	ShockAI().AddLocomotionKeyword('Burning', 1);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float selectionHeuristic(AI_Goal Goal)
{
	local EcologyAI AI;
	local NavigationPoint Point;
	local DouseGoal DouseGoal;

	AI = EcologyAI(Goal.resource.Pawn());
	assert(__NFUN_119__(AI, none));
	DouseGoal = DouseGoal(Goal);
	assert(__NFUN_119__(DouseGoal, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x155
	/*@Error*/
	Point = AI.FindPointInWater(DouseGoal.AvoidTarget, default.MinApproachDistanceToAttackTarget, default.MinDistanceToTarget, default.MinDesiredDistanceToMove, AI.GetMaxDistanceToMoveToWater());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x155
	/*@Error*/
	DouseGoal.PointInWater = Point;
	return 1.0000000;
	return 0.0000000;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	return;
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().BecomeAggressive();
	ShockAI().SetShouldRun();
	return;
	@NULL
}

function SetupForJumpInWaterAnimation()
{
	local Vector JumpInWaterAnimTranslation;
	local float JumpInWaterRotationYaw;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB7
	/*@Error*/
	JumpInWaterAnimation = ShockAI().GetJumpInWaterAnimation();
	JumpInWaterAnimLength = m_Pawn.GetAnimationLength(JumpInWaterAnimation);
	m_Pawn.GetAnimationAbsoluteMotion(JumpInWaterAnimation, JumpInWaterAnimLength, JumpInWaterAnimTranslation, JumpInWaterRotationYaw);
	JumpInWaterAnimationTranslationSize = __NFUN_225__(JumpInWaterAnimTranslation);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x49
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(PointInWater.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UDouseAction::execShouldStopMovingToWater(FFrame&, void* const)
native function bool ShouldStopMovingToWater();

function MoveToDouse()
{
	assert(__NFUN_119__(PointInWater, none));
	// End:0x5C
	if(Class'Engine.Pawn'.static.checkAlive(AvoidTarget))
	{
		ShockAI().SetAvoidTarget(AvoidTarget, MinApproachDistanceToAttackTarget);
		AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	}
	// End:0x1D4
	if(__NFUN_130__(__NFUN_177__(JumpInWaterAnimationTranslationSize, 0.0000000), ShockAI().GetPointToApproachTarget(JumpInWaterDestination, PointInWater, JumpInWaterAnimationTranslationSize)))
	{
		bMovingToJumpIntoWater = true;
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
		construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, JumpInWaterDestination);
		CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
		CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToWater;
		CurrentMoveToGoal.SetShouldModifyTravelThrottle(false);
		CurrentMoveToGoal.SetAlignmentAllowedDeltaYaw(JumpIntoWaterAllowedAlignmentDeltaYaw);
		goto J0x22E;
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
		construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, PointInWater);
		CurrentMoveToGoal.__NFUN_199__();
		CurrentMoveToGoal.postGoal(self);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x29B
		/*@Error*/
	}
	else
	{
		yield();
		goto J0x255;
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
		@NULL
	}
}

function PlayJumpInWaterAnimation()
{
	local float EndTime;
	local name RootBoneName;

	ShockAI().PlaySpeech('JumpingIntoWater');
	m_Pawn.__NFUN_3970__(3);
	JumpInWaterAnimationHandle = m_Pawn.PlayAnimationOnChannelFlatEaseIn(0, JumpInWaterAnimation, 0.1000000);
	EndTime = __NFUN_174__(Level().TimeSeconds, __NFUN_171__(m_Pawn.GetAnimationLengthScaled(JumpInWaterAnimationHandle), 0.7500000));
	RootBoneName = m_Pawn.GetHighBoneNameFromIndex(0);
	// End:0x14C
	if(__NFUN_176__(Level().TimeSeconds, EndTime))
	{
		LastRootPosition = m_Pawn.GetBoneLocation(RootBoneName);
		LastRootPositionUpdateTime = Level().TimeSeconds;
		yield();
		// [Loop Continue]
		goto J0xCF;
		m_Pawn.RootMotionVelocity.Z = __NFUN_171__(__NFUN_175__(m_Pawn.GetBoneLocation(RootBoneName).Z, LastRootPosition.Z), __NFUN_175__(Level().TimeSeconds, LastRootPositionUpdateTime));
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function Fall()
{
	// End:0x7C
	if(m_Pawn.IsOnCeiling())
	{
		m_Pawn.ClearLocalGravityDirection();
		ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.-1);
		ShockAI().NotifyCeilingVisionNoLongerDesired();
		m_Pawn.__NFUN_3970__(2);
	}
	m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(false);
	m_Pawn.GetRagdoll().Fall();
	__NFUN_256__(__NFUN_171__(m_Pawn.GetAnimationLengthScaled(JumpInWaterAnimationHandle), 0.2500000));
	m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(true);
	// End:0x198
	if(__NFUN_130__(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(2)), __NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0))))
	{
		yield();
		// [Loop Continue]
		goto J0x129;
		yield();
		// End:0x234
		if(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0)))
		{
		}
		// End:0x227
		if(__NFUN_154__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(2)))
		{
			m_Pawn.GetRagdoll().Rise();
			yield();
			// [Loop Continue]
			goto J0x1A2;
			m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(false);
			m_Pawn.GetRagdoll().SetMotorsEnabled(false);
		}
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x13A
	if(__NFUN_119__(PointInWater, none))
	{
		useResources(Class'VengeanceShared.AI_Resource'.2);
		// End:0x4E
		if(__NFUN_119__(PointInWater.FluidVolumeBelow, none))
		{
			SetupForJumpInWaterAnimation();
			ShockAI().AddLocomotionKeyword('Burning', Class'ShockAI.ShockAI'.-1);
		}
		ShockAI().BecomeAggressive();
		ShockAI().SetShouldRun();
		ShockAI().PlaySpeech('RunningToWater');
		MoveToDouse();
		// End:0x11A
		if(__NFUN_130__(bMovingToJumpIntoWater, ShockAI().IsBurning()))
		{
			PlayJumpInWaterAnimation();
			Fall();
			EcologyAI(m_Pawn).SetLastTimeDoused();
		}
		succeed();
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
	MinApproachDistanceToAttackTarget=200.0000000
	MinDistanceToTarget=200.0000000
	MinDesiredDistanceToMove=100.0000000
	JumpIntoWaterAllowedAlignmentDeltaYaw=1820
	satisfiesGoal=Class'ShockAI.DouseGoal'
	bExclusiveAction=true
}