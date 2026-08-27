class GathererLookAtTargetAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor Target;
var private MoveToGoal CurrentMoveToGoal;
var private float RequiredDistanceToTarget;
var private int GestureAnimationHandle;
var private bool bFinishLooking;
var private Actor RotationTarget;
var private float TimeToSpendLookingAtTarget;
var private config float RequiredDistanceToWallTargets;
var private config float RequiredDistanceToFloorTargets;
var config array<name> GestureFloorAnimations;
var config array<name> GestureWallAnimations;
var config array<name> InterestOnFloorLoopingAnimations;
var config array<name> InterestOnWallLoopingAnimations;
var config array<name> GetUpFromFloorAnimations;
var config array<name> EndWallInterestAnimations;
var private config float PauseAfterGesturingTime;
var private config Range TimeToHeadTrackToTargetRange;
var private config Range TimeBeforeMovingRange;
var private config Range TimeToSpendLookingAtTargetRange;
var private config float MinDegreesToRotateToTarget;
var private config float TimeToPlayDejectedAnimation;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	Gatherer(m_Pawn).AddSeenInterestingObject(Target);
	SetRequiredDistanceToTarget();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetRequiredDistanceToTarget()
{
	local Vector TargetBoundingCylinder;

	// End:0x37
	if(__NFUN_154__(int(Target.AILookAtType), int(1)))
	{
		RequiredDistanceToTarget = RequiredDistanceToFloorTargets;
		goto J0x6B;
		assert(__NFUN_154__(int(Target.AILookAtType), int(2)));
	}
	RequiredDistanceToTarget = RequiredDistanceToWallTargets;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10B
	/*@Error*/
	TargetBoundingCylinder = GetBoxCylinderExtent(Target.GetRenderBoundingBox());
	__NFUN_184__(RequiredDistanceToTarget, __NFUN_174__(__NFUN_245__(TargetBoundingCylinder.X, TargetBoundingCylinder.Y), m_Pawn.CollisionRadius));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
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
		// End:0x76
		if(m_Pawn.IsAnimationHandleValid(GestureAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(GestureAnimationHandle);
		ShockAI().AddLocomotionKeyword('HandsOnHips', Class'ShockAI.ShockAI'.-1);
	}
	ShockAI().AddLocomotionKeyword('PointingToThreat', Class'ShockAI.ShockAI'.-1);
	ShockAI().AddLocomotionKeyword('Tired', Class'ShockAI.ShockAI'.-1);
	Gatherer(m_Pawn).NotifyProtectorFinishedLookingAtTarget();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	instantSucceed();
	return;
	@NULL
}

function NotifyProtectorTellingUsToStopLooking()
{
	bFinishLooking = true;
	return;
	@NULL
}

function bool ShouldStopMovingToTarget()
{
	return __NFUN_130__(__NFUN_178__(VSizeSquared2D(__NFUN_216__(Target.Location, m_Pawn.Location)), __NFUN_171__(RequiredDistanceToTarget, RequiredDistanceToTarget)), m_Pawn.LineOfSightTo(Target));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToViewTarget()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	ShockAI().SetShouldRun();
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, Target);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToTarget;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool GetRotationToTarget(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(RotationTarget.Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Face(Actor FaceTarget)
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	assert(__NFUN_119__(FaceTarget, none));
	RotationTarget = FaceTarget;
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToTarget;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function name GetGestureAnimation()
{
	// End:0x4D
	if(__NFUN_130__(__NFUN_154__(int(Target.AILookAtType), int(1)), __NFUN_151__(GestureFloorAnimations.Length, 0)))
	{
		return GestureFloorAnimations[__NFUN_167__(GestureFloorAnimations.Length)];
		goto J0xA4;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x9A
		/*@Error*/
	}
	return GestureWallAnimations[__NFUN_167__(GestureWallAnimations.Length)];
	goto J0xA4;
	return 'None';
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function name GetLoopingInterestAnimation()
{
	// End:0x4D
	if(__NFUN_130__(__NFUN_154__(int(Target.AILookAtType), int(1)), __NFUN_151__(InterestOnFloorLoopingAnimations.Length, 0)))
	{
		return InterestOnFloorLoopingAnimations[__NFUN_167__(InterestOnFloorLoopingAnimations.Length)];
		goto J0xA4;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x9A
		/*@Error*/
	}
	return InterestOnWallLoopingAnimations[__NFUN_167__(InterestOnWallLoopingAnimations.Length)];
	goto J0xA4;
	return 'None';
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PlayGestureAnimations()
{
	local name GestureAnimation;

	GestureAnimation = GetGestureAnimation();
	// End:0x85
	if(__NFUN_255__(GestureAnimation, 'None'))
	{
		GestureAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GestureAnimation, Class'Engine.Actor'.4);
		m_Pawn.FinishAnimation(GestureAnimationHandle);
		GestureAnimation = GetLoopingInterestAnimation();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xEA
		/*@Error*/
		GestureAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GestureAnimation, Class'Engine.Actor'.8);
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayGetUpFromFloorAnimation()
{
	local name GetUpFromFloorAnimation;

	GetUpFromFloorAnimation = GetUpFromFloorAnimations[__NFUN_167__(GetUpFromFloorAnimations.Length)];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	GestureAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GetUpFromFloorAnimation);
	m_Pawn.FinishAnimation(GestureAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayEndWallInterestAnimation()
{
	local name EndWallInterestAnimation;

	EndWallInterestAnimation = EndWallInterestAnimations[__NFUN_167__(EndWallInterestAnimations.Length)];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	GestureAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, EndWallInterestAnimation);
	m_Pawn.FinishAnimation(GestureAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function LookAtTarget()
{
	local float TimeToLookAtTarget;

	TimeToLookAtTarget = RandRange(TimeToHeadTrackToTargetRange.Min, TimeToHeadTrackToTargetRange.Max);
	ShockAI().CasualLook(Target, 99999.0000000);
	__NFUN_256__(TimeToLookAtTarget);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{	J0x00:
	// End:0x5D [Loop If]
	if(__NFUN_129__(ShockAI().KeywordSearchOnBone(m_Pawn.GetHeadTargetTracker().GetHeadBoneIdx(), 'DisallowHeadTracking', 0.2000000)))
	{
		yield();
		// [Loop Continue]
		goto J0x00;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x34A
		/*@Error*/
	}
	LookAtTarget();
	bExclusiveAction = true;
	ShockAI().PlaySpeech('InvestigatedItem');
	ShockAI().AddLocomotionKeyword('PointingToThreat', 1);
	// End:0x161
	if(__NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(Rotator(__NFUN_216__(Target.Location, m_Pawn.Location)), m_Pawn.Rotation, int(__NFUN_171__(MinDegreesToRotateToTarget, 182.0444489)))))
	{
		Face(Target);
		__NFUN_256__(RandRange(TimeBeforeMovingRange.Min, TimeBeforeMovingRange.Max));
		MoveToViewTarget();
		Gatherer(m_Pawn).NotifyProtectorLookingAtTarget();
	}
	ShockAI().AddLocomotionKeyword('PointingToThreat', Class'ShockAI.ShockAI'.-1);
	Face(Target);
	ShockAI().StopTracking();
	PlayGestureAnimations();
	TimeToSpendLookingAtTarget = __NFUN_174__(Level().TimeSeconds, RandRange(TimeToSpendLookingAtTargetRange.Min, TimeToSpendLookingAtTargetRange.Max));
	// End:0x2D8
	if(__NFUN_132__(__NFUN_129__(bFinishLooking), __NFUN_178__(Level().TimeSeconds, TimeToSpendLookingAtTarget)))
	{
		yield();
		goto J0x295;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x306
		/*@Error*/
		PlayGetUpFromFloorAnimation();
		goto J0x310;
		PlayEndWallInterestAnimation();
		bExclusiveAction = false;
		ShockAI().AddLocomotionKeyword('Tired', 1);
		__NFUN_256__(TimeToPlayDejectedAnimation);
		succeed();
		stop;						
		@NULL
		@NULL
	}
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x03)
	/*@Error*/
}

defaultproperties
{
	RequiredDistanceToWallTargets=100.0000000
	RequiredDistanceToFloorTargets=75.0000000
	GestureFloorAnimations[0]="GA_reactionFloor_A"
	GestureWallAnimations[0]="GA_reactionWall_A"
	InterestOnFloorLoopingAnimations[0]="GA_InterestFloor_A"
	InterestOnWallLoopingAnimations[0]="GA_Fidget_C_idle"
	GetUpFromFloorAnimations[0]="GA_endInterestFloor_A"
	GetUpFromFloorAnimations[1]="GA_endInterestFloor_B"
	EndWallInterestAnimations[0]="GA_endInterestWall_A"
	EndWallInterestAnimations[1]="GA_endInterestWall_C"
	PauseAfterGesturingTime=5.0000000
	TimeToHeadTrackToTargetRange=(Min=0.7500000,Max=1.5000000)
	TimeBeforeMovingRange=(Min=1.0000000,Max=2.0000000)
	TimeToSpendLookingAtTargetRange=(Min=3.0000000,Max=5.0000000)
	MinDegreesToRotateToTarget=22.5000000
	TimeToPlayDejectedAnimation=5.0000000
	satisfiesGoal=Class'ShockAI.GathererLookAtTargetGoal'
}