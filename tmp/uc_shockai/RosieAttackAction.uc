class RosieAttackAction extends ProtectorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private ScoopUpGathererGoal CurrentScoopUpGathererGoal;
var private bool bChoosePointToAvoidTarget;
var private float TimeToStartMovingAgain;
var private float TimeToAdjustPositionToGatherer;
var private Vector PositionToProtectGatherer;
var private int NumTimesCouldntMoveWithoutGatherer;
var private Rotator DesiredRotationWhileAiming;
var private float MeleeAttackRange;
var private float RangedAttackRange;
var private bool bUseGrenadeWeapon;
var private float NextTimeForFindPointToAttackTest;
var config float MeleePushAIMagnitude;
var private config float TargetTooCloseToGathererDistance;
var private config Range TimeToStartMovingAgainRange;
var private config Range DesiredLocalDistanceToMoveWhileAttacking;
var private config float MinDistanceToApproachTargetWhileMovingAround;
var private config float ChanceToScoopUpGatherer;
var private config float MinDistanceToMoveAround;
var private config float MaxDistanceToMoveAround;
var private config float DistanceToMoveForMeleeAttack;
var private config float MoveToLocalPointChance;
var private config float MinTimeBetweenFindPointToAttackTests;
var private config float ThreeSixtyCanAttackDegrees;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	assert(__NFUN_119__(Level(), none));
	assert(__NFUN_119__(m_Pawn, none));
	MeleeAttackRange = IProvideMeleeDamageData(ShockGameInfo(Level().Game).GetItemFromClass(Rosie(m_Pawn).GetMeleeWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	RangedAttackRange = IProvideTraceDamageData(ShockGameInfo(Level().Game).GetItemFromClass(Rosie(m_Pawn).GetRangedWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	Protector(m_Pawn).__OnPushGetPushee__Delegate = OnPushGetPushee;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentScoopUpGathererGoal, none))
	{
		CurrentScoopUpGathererGoal.__NFUN_198__();
		CurrentScoopUpGathererGoal = none;
		Protector(m_Pawn).__OnPushGetPushee__Delegate = None;
	}
	// End:0x8F
	if(ShockAI().IsAimingWeapon())
	{
		ShockAI().StopAimingWeapon();
		ShockAI().SetAvoidTarget(none);
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(CharacterAttackAction).NotifyPausedDueToExclusivity();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5C
	/*@Error*/
	ShockAI().StopAimingWeapon();
	return;
	@NULL
}

function NotifyFinishedDodging()
{
	super(CharacterAttackAction).NotifyFinishedDodging();
	MoveToPoint = m_Pawn.Location;
	TimeToStartMovingAgain = __NFUN_174__(m_Pawn.Level.TimeSeconds, RandRange(TimeToStartMovingAgainRange.Min, TimeToStartMovingAgainRange.Max));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x113
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x113
	/*@Error*/
	ShockAI().AimWeaponAtTarget(Target);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool HasCurrentGatherer()
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	return __NFUN_130__(__NFUN_119__(CurrentGatherer, none), CurrentGatherer.IsAlive());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x41
	/*@Error*/
	return Target;
	return;
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	//native.outDestinationActor;
	//native.outDestinationLocation;	
	@NULL
	@NULL
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{
	//native.DesiredRotation;	
	@NULL
}

// Export URosieAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

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
	ShockAI().SetAvoidTarget(none);
	return;
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
	return Rosie(m_Pawn).GetRangedWeapon();
	return;
	@NULL
	CommanderAction
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return Rosie(m_Pawn).GetMeleeWeapon();
	return;
	@NULL
	CommanderAction
}

function AIRangedWeapon GetGrenadeWeapon()
{
	return Rosie(m_Pawn).GetGrenadeWeapon();
	return;
	@NULL
	CommanderAction
}

// Export URosieAttackAction::execShouldMoveToTargetForMeleeAttack(FFrame&, void* const)
native function bool ShouldMoveToTargetForMeleeAttack();

// Export URosieAttackAction::execIsWithinRangeForMeleeWeapon(FFrame&, void* const)
native function bool IsWithinRangeForMeleeWeapon();

function bool CanHitWithMeleeWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export URosieAttackAction::execCanAttackWithMeleeWeapon(FFrame&, void* const)
native function bool CanAttackWithMeleeWeapon();

// Export URosieAttackAction::execCanAttackWithThreeSixtyWeapon(FFrame&, void* const)
native function bool CanAttackWithThreeSixtyWeapon();

function bool CanHitWithRangedWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export URosieAttackAction::execCanAttackWithRangedWeapon(FFrame&, void* const)
native function bool CanAttackWithRangedWeapon();

function bool CanAttackWithGrenadeWeapon(bool bUseCurrentRotation)
{
	//native.bUseCurrentRotation;	
	@NULL
}

// Export URosieAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

function ScoopUpGatherer()
{
	assert(__NFUN_114__(CurrentScoopUpGathererGoal, none));
	CurrentScoopUpGathererGoal = Class'ShockAI.ScoopUpGathererGoal'.static.Allocate(self).;
	construct_AI_ResourceShockPawn(characterResource(), Target);
	CurrentScoopUpGathererGoal.__NFUN_199__();
	CurrentScoopUpGathererGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentScoopUpGathererGoal);
	CurrentScoopUpGathererGoal.unPostGoal(self);
	CurrentScoopUpGathererGoal.__NFUN_198__();
	CurrentScoopUpGathererGoal = none;
	Protector(m_Pawn).SetNextTimeCanPickUpGatherer();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool CanScoopUpGatherer()
{
	return __NFUN_130__(__NFUN_176__(__NFUN_195__(), ChanceToScoopUpGatherer), Protector(m_Pawn).CanPickUpGatherer());
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function NotifyBeginningAttack()
{
	// End:0x26
	if(__NFUN_130__(CanScoopUpGatherer(), CanInteractWithGatherer()))
	{
		ScoopUpGatherer();
	}
	super.NotifyBeginningAttack();
	return;
	@NULL
}

function UseGrenadeWeapon()
{
	local AIWeapon CurrentWeapon;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xE3
	/*@Error*/
	bUseGrenadeWeapon = true;
	// End:0x4D
	if(ShockAI().IsAimingWeapon())
	{
		ShockAI().StopAimingWeapon();
		// End:0x79
		if(__NFUN_130__(__NFUN_129__(IsRotatedForAttack()), CanAttackWithGrenadeWeapon(false)))
		{
		}
		yield();
		// [Loop Continue]
		goto J0x4D;
		// End:0xD7
		if(CanAttackWithGrenadeWeapon(true))
		{
		}
		CurrentWeapon = GetGrenadeWeapon();
		Rosie(m_Pawn).Equip(CurrentWeapon);
		UseCurrentWeapon(CurrentWeapon);
		bUseGrenadeWeapon = false;
		return;
		@NULL
		EcologyAI
		CommanderAction
	}
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
		CurrentWeapon = Rosie(m_Pawn).GetMeleeWeapon();
		goto J0x332;
		// End:0xDA
		if(CanAttackWithThreeSixtyWeapon())
		{
		}
		// End:0xAD
		if(ShockAI().IsAimingWeapon())
		{
			ShockAI().StopAimingWeapon();
			CurrentWeapon = Rosie(m_Pawn).GetThreeSixtyWeapon();
		}
		goto J0x332;
		assert(CanAttackWithRangedWeapon());
		UseGrenadeWeapon();
		CurrentWeapon = Rosie(m_Pawn).GetRangedWeapon();
	}
	// End:0x159
	if(__NFUN_129__(ShockAI().IsAimingWeapon()))
	{
		ShockAI().AimWeaponAtTarget(Target);
		// End:0x332
		if(__NFUN_132__(__NFUN_129__(ShockAI().IsWeaponLockedOnTarget()), __NFUN_129__(ShockAI().IsWeaponTargetWithinTrackingArea(Target))))
		{
		}
		log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " yield 3 - ShockAI().IsWeaponLockedOnTarget(): "), string(ShockAI().IsWeaponLockedOnTarget())), " ShockAI().IsAimingWeapon(): "), string(ShockAI().IsAimingWeapon())), " ShockAI().IsWeaponTargetWithinTrackingArea(Target): "), string(ShockAI().IsWeaponTargetWithinTrackingArea(Target))));
		yield();
		// End:0x32F
		if(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_132__(__NFUN_129__(ShockAI().IsAimingWeapon()), __NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Target))), IsWithinRangeForMeleeWeapon()), CanAttackWithMeleeWeapon()), __NFUN_129__(CanAttackWithRangedWeapon())))
		{
			return;
			// [Loop Continue]
			goto J0x159;
			assert(__NFUN_119__(CurrentWeapon, none));
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x398
			/*@Error*/
			Rosie(m_Pawn).Equip(CurrentWeapon);
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
	MeleePushAIMagnitude=10000.0000000
	TargetTooCloseToGathererDistance=300.0000000
	TimeToStartMovingAgainRange=(Min=2.0000000,Max=4.0000000)
	DesiredLocalDistanceToMoveWhileAttacking=(Min=300.0000000,Max=500.0000000)
	MinDistanceToApproachTargetWhileMovingAround=75.0000000
	ChanceToScoopUpGatherer=0.5000000
	MinDistanceToMoveAround=400.0000000
	MaxDistanceToMoveAround=3500.0000000
	DistanceToMoveForMeleeAttack=400.0000000
	MoveToLocalPointChance=0.5000000
	MinTimeBetweenFindPointToAttackTests=0.5000000
	ThreeSixtyCanAttackDegrees=90.0000000
	bCanDodgeWhileAttacking=true
	MinCanTargetHitBeforeDodgeTime=0.1500000
	MinDodgeTime=5.0000000
	DodgeChance=0.8000000
	DodgeFacingAngleDegrees=30.0000000
}