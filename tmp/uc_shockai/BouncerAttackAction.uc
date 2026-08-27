class BouncerAttackAction extends ProtectorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private int ThreatenAnimationHandle;
var private int StunAttackAnimationHandle;
var private int PostAttackAnimationHandle;
var private bool bShoulderAttackSuccessful;
var private bool bAttackInterrupted;
var private int StepBackAnimationHandle;
var config array<name> StepBackAnimations;
var config array<name> AttackThreatenAnimations;
var private config float PlayAttackThreatenAnimationChance;
var config array<name> ShoulderAttackHitAnimations;
var config array<name> ShoulderAttackMissedAnimations;
var private config float MinDesiredXYDistanceToTarget;
var private config float ThreeSixtyCanAttackDegrees;
var private config float DistanceToUseStunAttack;
var config array<name> StunAttackAnimations;
var private config Range TimeRangeBetweenStunAttacks;
var private config float DistanceToAlwaysRotateTowardsTarget;
var config float ChargeFOV;
var config float ChargePushDistance;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	Protector(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	ShockAI().MovementAttackTarget = Target;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7D
	/*@Error*/
	TellBotTargetToStayLow();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	// End:0x4D
	if(m_Pawn.IsAnimationHandleValid(ThreatenAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(ThreatenAnimationHandle);
		// End:0x90
		if(m_Pawn.IsAnimationHandleValid(StunAttackAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(StunAttackAnimationHandle);
		}
		// End:0xD3
		if(m_Pawn.IsAnimationHandleValid(StepBackAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(StepBackAnimationHandle);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x116
			/*@Error*/
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(PostAttackAnimationHandle);
		Protector(m_Pawn).__OnPushGetPushee__Delegate = None;
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	}
	ShockAI().MovementAttackTarget = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(CharacterAttackAction).NotifyPausedDueToExclusivity();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF0
	/*@Error*/
	// End:0x6A
	if(m_Pawn.IsAnimationHandleValid(ThreatenAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(ThreatenAnimationHandle);
		// End:0xAD
		if(m_Pawn.IsAnimationHandleValid(StunAttackAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(StunAttackAnimationHandle);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xF0
		/*@Error*/
		m_Pawn.SmartPerTrackEaseOutAnimation(PostAttackAnimationHandle);
		bAttackInterrupted = true;
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{
	local Vector DirectionToTarget, OffsetToTarget;

	OffsetToTarget = __NFUN_216__(Target.Location, m_Pawn.Location);
	DirectionToTarget = __NFUN_226__(OffsetToTarget);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAC
	/*@Error*/
	return Target;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnDamagedTarget()
{
	super(CharacterAttackAction).OnDamagedTarget();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	bShoulderAttackSuccessful = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredFocalPointOverride(out Vector DesiredFocalPoint)
{
	//native.DesiredFocalPoint;	
	@NULL
}

// Export UBouncerAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	//native.outDestinationActor;
	//native.outDestinationLocation;	
	@NULL
	@NULL
}

function OnMoveEnded()
{
	super(CharacterAttackAction).OnMoveEnded();
	ShockAI().SetShouldRun();
	return;
	@NULL
}

function OnReachedAvoidancePoint()
{
	super(CharacterAttackAction).OnReachedAvoidancePoint();
	ShockAI().bAvoidLastPath = true;
	return;
	@NULL
	CommanderAction
}

function NotifyCannotFindWayToDestination()
{
	super(CharacterAttackAction).NotifyCannotFindWayToDestination();
	// End:0x55
	if(__NFUN_180__(LastTimeCouldNotFindWayToDestination, 0.0000000))
	{
		// End:0x34
		if(ShouldTellBotTargetToStayLow())
		{
			TellBotTargetToStayLow();
			LastTimeCouldNotFindWayToDestination = Level().TimeSeconds;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x84
		/*@Error*/
	}
	StopMovingToAvoidancePoint();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyFoundWayToDestination()
{
	super(CharacterAttackAction).NotifyFoundWayToDestination();
	LastTimeCouldNotFindWayToDestination = 0.0000000;
	return;
	@NULL
	CommanderAction
}

// Export UBouncerAttackAction::execCanAttackWithShoulder(FFrame&, void* const)
native function bool CanAttackWithShoulder();

// Export UBouncerAttackAction::execCanAttackWithHands(FFrame&, void* const)
native function bool CanAttackWithHands();

// Export UBouncerAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

function AIWeapon ChooseWeapon()
{
	// End:0x31
	if(CanAttackWithShoulder())
	{
		return Bouncer(m_Pawn).GetShoulderWeapon();
		goto J0x83;
		// End:0x62
		if(CanAttackWithHands())
		{
		}
		return Bouncer(m_Pawn).GetHandWeapon();
		goto J0x83;
		return Bouncer(m_Pawn).GetThreeSixtyWeapon();
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

// Export UBouncerAttackAction::execIsPlayingThreatenAnimation(FFrame&, void* const)
private native function bool IsPlayingThreatenAnimation();

function name GetAttackThreatenAnimation()
{
	return AttackThreatenAnimations[__NFUN_167__(AttackThreatenAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function bool CanDoStunAttack()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(bMovingToAvoidancePoint), __NFUN_179__(m_Pawn.Level.TimeSeconds, Bouncer(m_Pawn).GetNextTimeCanUseStunAttack())), __NFUN_151__(StunAttackAnimations.Length, 0)), Target.__NFUN_303__('ShockPlayer')), IsPointWithinCylinder(Target.Location, m_Pawn.Location, DistanceToUseStunAttack, __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function DoStunAttack()
{
	local name StunAttackAnimation;

	StunAttackAnimation = StunAttackAnimations[__NFUN_167__(StunAttackAnimations.Length)];
	StunAttackAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, StunAttackAnimation);
	m_Pawn.FinishAnimation(StunAttackAnimationHandle);
	Bouncer(m_Pawn).SetNextTimeCanUseStunAttack(__NFUN_174__(m_Pawn.Level.TimeSeconds, RandRange(TimeRangeBetweenStunAttacks.Min, TimeRangeBetweenStunAttacks.Max)));
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function NotifyBeginningAttack()
{
	PickUpGatherer();
	super.NotifyBeginningAttack();
	MoveToActor = Target;
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
}

function PlayAttackThreatenAnimation()
{
	local name AttackThreatenAnimation;

	AttackThreatenAnimation = GetAttackThreatenAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x95
	/*@Error*/
	ThreatenAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, AttackThreatenAnimation);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x95
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0x56;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function NotifyCannotAttackTarget()
{
	super(CharacterAttackAction).NotifyCannotAttackTarget();
	// End:0x42
	if(__NFUN_130__(Target.__NFUN_303__('Aggressor'), __NFUN_176__(__NFUN_195__(), PlayAttackThreatenAnimationChance)))
	{
		PlayAttackThreatenAnimation();
		CheckIfShouldMoveToAvoidancePoint();
		// End:0x63
		if(CanDoStunAttack())
		{
		}
		DoStunAttack();
		return;
		@NULL
		EcologyAI
	}
	BioshockMovementAction
}

function bool ShouldStepBack()
{
	return __NFUN_130__(__NFUN_130__(IsPointWithinCylinder(Target.Location, m_Pawn.Location, MinDesiredXYDistanceToTarget, __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000)), __NFUN_177__(__NFUN_219__(__NFUN_216__(Target.Location, m_Pawn.Location), Vector(m_Pawn.Rotation)), 0.0000000)), Bouncer(m_Pawn).CanStepBack());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function stepback()
{
	local name StepBackAnimation;

	StepBackAnimation = StepBackAnimations[__NFUN_167__(StepBackAnimations.Length)];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	StepBackAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, StepBackAnimation);
	m_Pawn.FinishAnimation(StepBackAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function NotifyFinishedAttackingTarget()
{
	super(CharacterAttackAction).NotifyFinishedAttackingTarget();
	// End:0x24
	if(ShouldStepBack())
	{
		stepback();
		goto J0x4D;
		// End:0x4D
		if(__NFUN_130__(bShoulderAttackSuccessful, __NFUN_176__(__NFUN_195__(), PlayAttackThreatenAnimationChance)))
		{
		}
		PlayAttackThreatenAnimation();
		return;
		@NULL
		EcologyAI
	}
	J0x4D:

	BioshockMovementAction
}

function AttackTarget()
{
	local AIWeapon CurrentWeapon;
	local name PostAttackAnimation;

	bAttackInterrupted = false;
	bShoulderAttackSuccessful = false;
	CurrentWeapon = ChooseWeapon();
	AssertWithDescription(__NFUN_119__(CurrentWeapon, none), "BouncerAttackAction::AttackTarget - none of the weapons CanHit the target!");
	// End:0xE5
	if(__NFUN_119__(Bouncer(m_Pawn).GetActiveHoldable(), CurrentWeapon))
	{
		Bouncer(m_Pawn).Equip(CurrentWeapon);
		// End:0x1A5
		if(__NFUN_114__(CurrentWeapon, Bouncer(m_Pawn).GetShoulderWeapon()))
		{
			// End:0x18C
			if(__NFUN_130__(__NFUN_129__(m_Pawn.bBlockActors), m_Pawn.IsAreaClearForMovement(m_Pawn.Location, m_Pawn.GetCylinderExtent(), true)))
			{
			}
			m_Pawn.__NFUN_262__(true, true, true);
			ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
			UseCurrentWeapon(CurrentWeapon);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2E0
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2E0
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x244
			/*@Error*/
		}
	}
	PostAttackAnimation = ShoulderAttackHitAnimations[__NFUN_167__(ShoulderAttackHitAnimations.Length)];
	goto J0x264;
	PostAttackAnimation = ShoulderAttackMissedAnimations[__NFUN_167__(ShoulderAttackMissedAnimations.Length)];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2C7
	/*@Error*/
	PostAttackAnimationHandle = m_Pawn.PlayAnimationOnChannelInstantEaseIn(3, PostAttackAnimation);
	m_Pawn.FinishAnimation(PostAttackAnimationHandle);
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

defaultproperties
{
	StepBackAnimations[0]="BO_jumpBack_A"
	AttackThreatenAnimations[0]="BO_Threaten_B"
	AttackThreatenAnimations[1]="BO_Threaten_D"
	ShoulderAttackHitAnimations[0]="BO_AttackShoulderSlamLONG_Hit"
	ShoulderAttackMissedAnimations[0]="BO_AttackShoulderSlamLONG_Miss"
	MinDesiredXYDistanceToTarget=200.0000000
	ThreeSixtyCanAttackDegrees=120.0000000
	DistanceToUseStunAttack=700.0000000
	StunAttackAnimations[0]="BO_ThreatenA"
	TimeRangeBetweenStunAttacks=(Min=10.0000000,Max=15.0000000)
	DistanceToAlwaysRotateTowardsTarget=1000.0000000
	ChargeFOV=45.0000000
	ChargePushDistance=250.0000000
	AttackBehaviorAllowedYawRotationErrorTwoByte=8192
	HangoutTimeRange=(Min=5.0000000,Max=10.0000000)
	MinDistanceToMoveAwayForLineOfSight=1500.0000000
	MinDistanceToMoveOut=300.0000000
	MinDistanceToTargetWhileAvoiding=300.0000000
	MeleeInterruptDegrees=120.0000000
	MeleeInterruptMaxVelocity=50.0000000
	LocomotionResumeAlignmentThreshold=0.3000000
}