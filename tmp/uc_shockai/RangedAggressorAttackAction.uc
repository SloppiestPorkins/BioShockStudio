class RangedAggressorAttackAction extends AggressorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private Vector TargetPositionAtPointSelection;
var private bool bJustDamagedByTarget;
var private bool bIsAdjustingPosition;
var private bool bSetUsablePoint;
var private int PushAnimationHandle;
var private int ReloadAnimationHandle;
var private float BehaviorStartTime;
var private float LastTimeSwitchedMovementRate;
var private float MeleeAttackRange;
var private float RangedWeaponRange;
var private int NumTimesAttackedWithRangedWeapon;
var private float NextTimeCanReload;
var private float TimeToStartMovingAgain;
var private Rotator DesiredRotationWhileAiming;
var private float NextTimeForFindPointToAttackTest;
var private bool bRunningForCover;
var private float NextTimeCanCheckForCover;
var private float LastTimeMadeItToCover;
var config name MeleePushDamageStimuliSetName;
var config float PushFOV;
var config float PushDistance;
var config array<name> CoverRollAnimations;
var private config float MinDistanceToApproachTargetWhileMovingAround;
var private config float MinDistanceToAttackWithRangedWeapon;
var private config Range MoveRangeForPositionAdjust;
var config float TimeToWaitAfterBeginningAttackBeforeMoving;
var config float MinTimeBetweenMovementRateChanges;
var config float ChanceToReload;
var config Range TimeRangeBetweenReloads;
var private config float DistanceToMoveForMeleeAttack;
var private config float MoveToLocalPointChance;
var private config float MinDistanceToMoveAround;
var private config float MaxDistanceToMoveAround;
var private config Range TimeToStartMovingAgainRange;
var private config float MinTimeBetweenFindPointToAttackTests;
var private config float MoveToCoverChanceAgainstPlayer;
var private config float MoveToCoverChanceAgainstAI;
var private config float FoundCoverMinTimeToReload;
var private config float MinTimeBetweenCoverChecks;
var private config float DotThresholdToRunForCoverPlayerTarget;
var private config float DotThresholdToRunForCoverAITarget;
var private config float MinTimeBetweenDiveRollAndRunningForCover;
var private config float ChanceToDiveRollOutFromCover;
var private config Range InitialTimeBeforeMovingRange;
var config array<name> PushAnimations;
var config array<Vector> CoverRollTranslations;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	MoveToPoint = m_Pawn.Location;
	TargetPositionAtPointSelection = Target.Location;
	ShockAI(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	RangedWeaponRange = IProvideTraceDamageData(ShockGameInfo(Level().Game).GetItemFromClass(GetRangedWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	MeleeAttackRange = IProvideMeleeDamageData(ShockGameInfo(Level().Game).GetItemFromClass(GetMeleeWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	BehaviorStartTime = m_Pawn.Level.TimeSeconds;
	FindCoverRollTranslations();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x22F
	/*@Error*/
	NextTimeForFindPointToAttackTest = __NFUN_174__(Level().TimeSeconds, RandRange(InitialTimeBeforeMovingRange.Min, InitialTimeBeforeMovingRange.Max));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FindCoverRollTranslations()
{
	local int i;
	local name TestCoverRollAnimation;
	local float TestCoverAnimLength, TestCoverRollRotationYaw;
	local Vector TestCoverRollTranslation;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD1
	/*@Error*/
	TestCoverRollAnimation = CoverRollAnimations[i];
	TestCoverAnimLength = m_Pawn.GetAnimationLength(TestCoverRollAnimation);
	m_Pawn.GetAnimationAbsoluteMotion(TestCoverRollAnimation, TestCoverAnimLength, TestCoverRollTranslation, TestCoverRollRotationYaw);
	CoverRollTranslations[CoverRollTranslations.Length] = TestCoverRollTranslation;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	ShockAI().SetAvoidTarget(none);
	ShockAI(m_Pawn).__OnPushGetPushee__Delegate = None;
	// End:0x7F
	if(ShockAI().IsAimingWeapon())
	{
		ShockAI().StopAimingWeapon();
		// End:0xC2
		if(m_Pawn.IsAnimationHandleValid(PushAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(PushAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x105
		/*@Error*/
		m_Pawn.SmartPerTrackEaseOutAnimation(ReloadAnimationHandle);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(CharacterAttackAction).NotifyRunningDueToExclusivity();
	BehaviorStartTime = m_Pawn.Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(CharacterAttackAction).NotifyPausedDueToExclusivity();
	MoveToPoint = m_Pawn.Location;
	// End:0x5D
	if(ShockAI().IsAimingWeapon())
	{
		ShockAI().StopAimingWeapon();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OnDamagedByTarget()
{
	super(CharacterAttackAction).OnDamagedByTarget();
	bJustDamagedByTarget = true;
	return;
	@NULL
	CommanderAction
}

function bool CanPushTarget()
{
	local Vector DirectionToTarget, OffsetToTarget;

	OffsetToTarget = __NFUN_216__(Target.Location, m_Pawn.Location);
	DirectionToTarget = __NFUN_226__(OffsetToTarget);
	return __NFUN_130__(__NFUN_176__(__NFUN_225__(OffsetToTarget), PushDistance), __NFUN_179__(__NFUN_219__(Vector(m_Pawn.Rotation), DirectionToTarget), __NFUN_188__(__NFUN_171__(PushFOV, 0.0174533))));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{
	local Vector DirectionToTarget;
	local DamageStimuliSet DamageSet;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x121
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x117
	/*@Error*/
	DamageSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(MeleePushDamageStimuliSetName);
	DirectionToTarget = __NFUN_226__(__NFUN_216__(Target.Location, m_Pawn.Location));
	ShockAI(Target).Fall(Target.Location, __NFUN_211__(DirectionToTarget), DirectionToTarget, 0.0000000, 'None', 'None', DamageSet);
	DamageSet.__NFUN_200__();
	return Target;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyFinishedDodging()
{
	super(CharacterAttackAction).NotifyFinishedDodging();
	MoveToPoint = m_Pawn.Location;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCC
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCC
	/*@Error*/
	ShockAI().AimWeaponAtTarget(Target);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	//native.DesiredRotation;	
	@NULL
}

// Export URangedAggressorAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	//native.outDestinationActor;
	//native.outDestinationLocation;	
	@NULL
	@NULL
}

// Export URangedAggressorAttackAction::execShouldMoveToTargetForMeleeAttack(FFrame&, void* const)
private native function bool ShouldMoveToTargetForMeleeAttack();

// Export URangedAggressorAttackAction::execIsCloseToTarget(FFrame&, void* const)
private native function bool IsCloseToTarget();

// Export URangedAggressorAttackAction::execIsAdjustingPosition(FFrame&, void* const)
private native function bool IsAdjustingPosition();

function OnMoveStarted()
{
	super(CharacterAttackAction).OnMoveStarted();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x59
	/*@Error*/
	ShockAI().AimWeaponAtTarget(Target);
	return;
	@NULL
	CommanderAction
}

function OnMoveEnded()
{
	super(CharacterAttackAction).OnMoveEnded();
	bSetUsablePoint = false;
	bIsAdjustingPosition = false;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB2
	/*@Error*/
	bRunningForCover = false;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB2
	/*@Error*/
	LastTimeMadeItToCover = m_Pawn.Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnTurnStarted()
{
	super(CharacterAttackAction).OnTurnStarted();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x59
	/*@Error*/
	ShockAI().AimWeaponAtTarget(Target);
	return;
	@NULL
	CommanderAction
}

function NotifyFoundWayToDestination()
{
	super(CharacterAttackAction).NotifyFoundWayToDestination();
	// End:0x30
	if(__NFUN_114__(MoveToActor, Target))
	{
		LastTimeCouldNotFindWayToDestination = 0.0000000;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyCannotFindWayToDestination()
{
	super(CharacterAttackAction).NotifyCannotFindWayToDestination();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x57
	/*@Error*/
	LastTimeCouldNotFindWayToDestination = Level().TimeSeconds;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsWithinRangeForRangedWeapon()
{
	local float DistanceToTarget;

	DistanceToTarget = __NFUN_225__(__NFUN_216__(Target.Location, m_Pawn.Location));
	return __NFUN_178__(DistanceToTarget, IProvideTraceDamageData(ShockGameInfo(Level().Game).GetItemFromClass(RangedAggressor(m_Pawn).GetRangedWeapon().GetDefaultAmmoSelection())).GetAttackRange());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function NotifyMovingToAvoidancePoint()
{
	super(CharacterAttackAction).NotifyMovingToAvoidancePoint();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4E
	/*@Error*/
	ShockAI().StopAimingWeapon();
	return;
	@NULL
}

function AIRangedWeapon GetRangedWeapon()
{
	return RangedAggressor(m_Pawn).GetRangedWeapon();
	return;
	@NULL
	CommanderAction
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return RangedAggressor(m_Pawn).GetMeleeWeapon();
	return;
	@NULL
	CommanderAction
}

// Export URangedAggressorAttackAction::execIsWithinRangeForMeleeWeapon(FFrame&, void* const)
private native function bool IsWithinRangeForMeleeWeapon();

function bool CanHitWithMeleeWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export URangedAggressorAttackAction::execCanAttackWithMeleeWeapon(FFrame&, void* const)
private native function bool CanAttackWithMeleeWeapon();

function bool CanHitWithRangedWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export URangedAggressorAttackAction::execCanAttackWithRangedWeapon(FFrame&, void* const)
private native function bool CanAttackWithRangedWeapon();

// Export URangedAggressorAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

function PushTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x68
	/*@Error*/
	PushAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, PushAnimations[__NFUN_167__(PushAnimations.Length)]);
	m_Pawn.FinishAnimation(PushAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function NotifyThreatenBegan()
{
	super.NotifyThreatenBegan();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3D
	/*@Error*/
	ShockAI().StopAimingWeapon();
	return;
	@NULL
}

function bool ShouldReload()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xD0
	/*@Error*/
	return true;
	goto J0xD2;
	return false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Reload()
{
	local name ReloadAnimation;

	ReloadAnimation = RangedAggressor(m_Pawn).GetReloadAnimationName();
	// End:0x8C
	if(__NFUN_255__(ReloadAnimation, 'None'))
	{
		ReloadAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ReloadAnimation);
		m_Pawn.FinishAnimation(ReloadAnimationHandle);
		NextTimeCanReload = __NFUN_174__(Level().TimeSeconds, RandRange(TimeRangeBetweenReloads.Min, TimeRangeBetweenReloads.Max));
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

// Export URangedAggressorAttackAction::execGetDiveRollAnimation(FFrame&, void* const)
private native function name GetDiveRollAnimation();

function DiveRoll()
{
	local name RollOutAnimation;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xEF
	/*@Error*/
	yield();
	RollOutAnimation = GetDiveRollAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEF
	/*@Error*/
	ReloadAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, RollOutAnimation);
	m_Pawn.FinishAnimation(ReloadAnimationHandle);
	NextTimeCanCheckForCover = __NFUN_174__(m_Pawn.Level.TimeSeconds, MinTimeBetweenDiveRollAndRunningForCover);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function NotifyCannotAttackTarget()
{
	super(CharacterAttackAction).NotifyCannotAttackTarget();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2B
	/*@Error*/
	Reload();
	DiveRoll();
	return;
	@NULL
}

function NotifyFinishedAttackingTarget()
{
	super(CharacterAttackAction).NotifyFinishedAttackingTarget();
	// End:0x21
	if(CanPushTarget())
	{
		PushTarget();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x38
		/*@Error*/
	}
	Threaten();
	return;
	@NULL
}

function AttackTarget()
{
	local AIWeapon CurrentWeapon;

	// End:0x6D
	if(CanAttackWithMeleeWeapon())
	{
		// End:0x40
		if(ShockAI().IsAimingWeapon())
		{
			ShockAI().StopAimingWeapon();
		}
		CurrentWeapon = RangedAggressor(m_Pawn).GetMeleeWeapon();
		goto J0x2C6;
		assert(CanAttackWithRangedWeapon());
	}
	CurrentWeapon = RangedAggressor(m_Pawn).GetRangedWeapon();
	// End:0xE2
	if(__NFUN_129__(ShockAI().IsAimingWeapon()))
	{
		ShockAI().AimWeaponAtTarget(Target);
		// End:0x2BB
		if(__NFUN_132__(__NFUN_129__(ShockAI().IsWeaponLockedOnTarget()), __NFUN_129__(ShockAI().IsWeaponTargetWithinTrackingArea(Target))))
		{
		}
		log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " yield 3 - ShockAI().IsWeaponLockedOnTarget(): "), string(ShockAI().IsWeaponLockedOnTarget())), " ShockAI().IsAimingWeapon(): "), string(ShockAI().IsAimingWeapon())), " ShockAI().IsWeaponTargetWithinTrackingArea(Target): "), string(ShockAI().IsWeaponTargetWithinTrackingArea(Target))));
		yield();
		// End:0x2B8
		if(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_129__(ShockAI().IsAimingWeapon()), __NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Target))), IsWithinRangeForMeleeWeapon()), CanAttackWithMeleeWeapon()), __NFUN_129__(CanAttackWithRangedWeapon())))
		{
			return;
			// [Loop Continue]
			goto J0xE2;
			__NFUN_163__(NumTimesAttackedWithRangedWeapon);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x31D
			/*@Error*/
			RangedAggressor(m_Pawn).Equip(CurrentWeapon);
		}
	}
	UseCurrentWeapon(CurrentWeapon);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

defaultproperties
{
	MeleePushDamageStimuliSetName="AggressorPushStimuliSet"
	PushFOV=40.0000000
	PushDistance=125.0000000
	MinTimeBetweenFindPointToAttackTests=0.5000000
	MoveToCoverChanceAgainstPlayer=0.7500000
	MoveToCoverChanceAgainstAI=0.5000000
	FoundCoverMinTimeToReload=1.0000000
	MinTimeBetweenCoverChecks=0.2500000
	DotThresholdToRunForCoverPlayerTarget=0.7070000
	DotThresholdToRunForCoverAITarget=0.5000000
	MinTimeBetweenDiveRollAndRunningForCover=5.0000000
	ChanceToDiveRollOutFromCover=0.7500000
	InitialTimeBeforeMovingRange=(Min=0.0000000,Max=3.0000000)
	bCanDodgeWhileAttacking=true
	MinCanTargetHitBeforeDodgeTime=0.1000000
	MinDodgeTime=5.0000000
	DodgeChance=0.8000000
	MinDodgeDistance=75.0000000
	DodgeFacingAngleDegrees=45.0000000
	InitialReactionChance=1.0000000
	AttackBehaviorAllowedYawRotationErrorTwoByte=8192
}