class CharacterAttackAction extends BioshockCharacterAction implements IInterestedActorDestroyed
	abstract
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

const MIN_TARGET_TAUNT_AGE = 2.0f;
const MAX_TARGET_TAUNT_AGE = 5.0f;
const TIME_TO_HAVEBOTTARGET_STAYLOW = 15.0;

var(Parameters) ShockPawn Target;
var private MoveToGoal CurrentMoveToGoal;
var private DodgeGoal CurrentDodgeGoal;
var private Vector MoveToPoint;
var private Actor MoveToActor;
var private float LastTimeCouldAttack;
var private bool bWasAbleToAttackAtLastOpportunity;
var private int InitialReactionAnimationHandle;
var private float LoopStartTime;
var private float LastTimeTriggeredFleedSpeech;
var private float LastTimeTriggeredNoLOSSpeech;
var private float LastTimeCouldNotFindWayToDestination;
var private bool bMovingToAvoidancePoint;
var private bool bLookForAvoidancePointOnNextUpdate;
var private float NextTimeCanUpdateAvoidancePoint;
var private float AvoidanceHangoutTimeLeft;
var private bool bWillMoveAwayForFootsteps;
var config bool bCanDodgeWhileAttacking;
var config float MinCanTargetHitBeforeDodgeTime;
var private float StartCanTargetHitTargetTime;
var config float MinDodgeTime;
var private float LastDodgeTime;
var config float DodgeChance;
var config float MinDodgeDistance;
var config float DodgeFacingAngleDegrees;
var private float DodgeFacingDot;
var config array<name> InitialReactionAnimations;
var config array<name> CeilingInitialReactionAnimations;
var config float InitialReactionChance;
var config float InitialReactionIgnoreDamageTime;
var config Range DistanceFromTargetToDoInitialReactionRange;
var config float MinTimeToTriggerFleedSpeech;
var config float MinTimeToReTriggerFleedSpeech;
var config float FleedSpeechChance;
var config float MinTimeToTriggerNoLOSSpeech;
var config float MinTimeToReTriggerNoLOSSpeech;
var config float NoLOSSpeechChance;
var config int AttackBehaviorAllowedYawRotationErrorTwoByte;
var config float RecentFootstepsTime;
var config Range HangoutTimeRange;
var config float ChanceToMoveAwayUponHearingFootsteps;
var config float MinDistanceToMoveAwayUponHearingFootsteps;
var config float MinDistanceToMoveAwayForLineOfSight;
var config float MinDistanceToMoveOut;
var config float UnreachableTimeBeforeAvoidingTarget;
var config float MinDistanceToTargetWhileAvoiding;
var config float MinDistanceToMoveWhileAvoiding;
var config float AvoidUpdateAvoidancePointTime;
var private float NextTauntTime;
var private config Range CombatTauntDelay;
var private config float MeleeInterruptDegrees;
var private config float MeleeInterruptMaxVelocity;
var private config float LocomotionResumeAlignmentThreshold;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	// End:0xAA
	if(Class'Engine.Pawn'.static.checkAlive(Target))
	{
		ShockAI().dispatchMessage(Class'ShockAI.MessageAIAttackingTarget'.static.Allocate(self)., construct_NameName(m_Pawn.Label, Target.Label));
		ShockAI().BecomeAggressive();
		ShockAI().StopAnyScriptedLoopingAnimations();
	}
	TriggerAttackingSpeech();
	ShockAI().NotifyAttackingVisionDesired();
	DodgeFacingDot = __NFUN_188__(__NFUN_171__(0.0174533, DodgeFacingAngleDegrees));
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	ShockAI().LastTauntTime = -1.0000000;
	ShockAI().LastResponseTime = -2.0000000;
	NextTauntTime = __NFUN_174__(m_Pawn.Level.TimeSeconds, 3.0000000);
	ResetRangedWeaponAccuracy();
	MoveToPoint = m_Pawn.Location;
	ShockAI().NotifyControllablesControllerDealtDamage(Target, 1.0000000);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetRangedWeaponAccuracy()
{
	local AIRangedWeapon AIRangedWeapon;

	AIRangedWeapon = GetRangedWeapon();
	// End:0x43
	if(__NFUN_119__(AIRangedWeapon, none))
	{
		AIRangedWeapon.ResetChangingAccuracy(Target);
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function TriggerAttackingSpeech()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x1C3
	/*@Error*/
	// End:0x63
	if(Target.__NFUN_303__('ShockPlayer'))
	{
		ShockAI().PlaySpeech('ChallengedPlayer');
		goto J0x1A2;
		// End:0xA3
		if(Target.__NFUN_303__('Protector'))
		{
		}
		ShockAI().PlaySpeech('ChallengedProtector');
		goto J0x1A2;
		// End:0xE3
		if(Target.__NFUN_303__('Gatherer'))
		{
		}
		ShockAI().PlaySpeech('ChallengedGatherer');
		goto J0x1A2;
		// End:0x123
		if(Target.__NFUN_303__('Aggressor'))
		{
		}
		ShockAI().PlaySpeech('ChallengedAggressor');
		goto J0x1A2;
		// End:0x181
		if(__NFUN_132__(Target.__NFUN_303__('SecurityBot'), Target.__NFUN_303__('Turret')))
		{
		}
		ShockAI().PlaySpeech('ChallengedMachine');
		goto J0x1A2;
		ShockAI().PlaySpeech('ChallengedGeneric');
		ShockAI().PlaySpeech('Attacking');
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function TriggerTaunt()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x151
	/*@Error*/
	ShockAI().PlaySpeech('CombatTaunt');
	// End:0xA9
	if(ShouldRespondToTaunt())
	{
		ShockAI().LastResponseTime = m_Pawn.Level.TimeSeconds;
		ShockAI().LastTauntTime = m_Pawn.Level.TimeSeconds;
	}
	NextTauntTime = __NFUN_174__(m_Pawn.Level.TimeSeconds, RandRange(CombatTauntDelay.Min, CombatTauntDelay.Max));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldRespondToTaunt()
{
	local ShockAI TargetAI;

	TargetAI = ShockAI(Target);
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_119__(TargetAI, none), __NFUN_179__(TargetAI.LastTauntTime, float(0))), __NFUN_181__(TargetAI.LastTauntTime, TargetAI.LastResponseTime)), __NFUN_181__(ShockAI().LastTauntTime, ShockAI().LastResponseTime)), __NFUN_179__(TargetAI.LastTauntTime, __NFUN_175__(TargetAI.Level.TimeSeconds, 5.0000000))), __NFUN_178__(TargetAI.LastTauntTime, __NFUN_175__(TargetAI.Level.TimeSeconds, 2.0000000)));
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
		// End:0x5C
		if(__NFUN_119__(CurrentDodgeGoal, none))
		{
			CurrentDodgeGoal.__NFUN_198__();
		}
		CurrentDodgeGoal = none;
		// End:0x9F
		if(m_Pawn.IsAnimationHandleValid(InitialReactionAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(InitialReactionAnimationHandle);
		}
		// End:0xD1
		if(m_Pawn.IsAlive())
		{
			ShockAI().StopWeaponFire();
			ShockAI().StopTracking();
		}
		ShockAI().NotifyAttackingVisionNoLongerDesired();
		ShockAI().StopSpeech('CombatTaunt');
	}
	ShockAI().StopSpeech('Attacking');
	m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	// End:0x3F
	if(__NFUN_129__(ShockAI().IsFrozen()))
	{
		ShockAI().StopWeaponFire();
		ShockAI().StopSpeech('Attacking');
	}
	return;
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().PlaySpeech('Attacking');
	ShockAI().BecomeAggressive();
	return;
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x21
	/*@Error*/
	instantSucceed();
	return;
	@NULL
	CommanderAction
}

function goalAchievedCB(AI_Goal Goal, AI_Action Child)
{
	super(AI_Action).goalAchievedCB(Goal, Child);
	assert(__NFUN_119__(Goal, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	NotifyFinishedDodging();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function goalNotAchievedCB(AI_Goal Goal, AI_Action Child, ActionBase.ACT_ErrorCodes errorCode)
{
	super(AI_Action).goalNotAchievedCB(Goal, Child, errorCode);
	assert(__NFUN_119__(Goal, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x55
	/*@Error*/
	NotifyFinishedDodging();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnDamagedByTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x1D
	/*@Error*/
	StopHangingOut();
	return;
	@NULL
}

function OnDamagedTarget()
{
	return;
}

// Export UCharacterAttackAction::execCheckShouldDodge(FFrame&, void* const)
protected native function bool CheckShouldDodge();

// Export UCharacterAttackAction::execIsDodging(FFrame&, void* const)
native function bool IsDodging();

function Dodge(bool bTargetHasMeleeWeaponEquipped)
{
	assert(__NFUN_132__(__NFUN_114__(CurrentDodgeGoal, none), CurrentDodgeGoal.hasCompleted()));
	// End:0x6C
	if(__NFUN_119__(CurrentDodgeGoal, none))
	{
		CurrentDodgeGoal.unPostGoal(self);
		CurrentDodgeGoal.__NFUN_198__();
		CurrentDodgeGoal = none;
		CurrentDodgeGoal = Class'ShockAI.DodgeGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceBool(characterResource(), bTargetHasMeleeWeaponEquipped);
	CurrentDodgeGoal.__NFUN_199__();
	CurrentDodgeGoal.postGoal(self);
	LastDodgeTime = Level().TimeSeconds;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

protected function NotifyFinishedDodging()
{
	return;
}

function bool ShouldTellBotTargetToStayLow()
{
	return __NFUN_130__(Target.__NFUN_303__('SecurityBot'), __NFUN_129__(SecurityBot(Target).IsAttacking(ShockAI())));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function TellBotTargetToStayLow()
{
	SecurityBot(Target).TellToStayLow(15.0000000, m_Pawn.CollisionRadius);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function ShockPawn GetTarget()
{
	return Target;
	return;
	@NULL
}

function bool CanAttackTarget()
{
	return false;
	return;
}

function bool InternalCanAttackTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x98
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x98
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x96
	/*@Error*/
	EcologyFighter(m_Pawn).RemoveUnreachableTarget(Target);
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UCharacterAttackAction::execIsRotatedForAttack(FFrame&, void* const)
native function bool IsRotatedForAttack();

// Export UCharacterAttackAction::execIsAttackingTarget(FFrame&, void* const)
native function bool IsAttackingTarget();

function bool IsAttackingTargetWith(AIWeapon Weapon)
{
	//native.Weapon;	
	@NULL
}

function bool ShouldInterruptAttack(AIWeapon Weapon)
{
	//native.Weapon;	
	@NULL
}

function AIRangedWeapon GetRangedWeapon()
{
	return none;
	return;
}

function AIMeleeWeapon GetMeleeWeapon()
{
	return none;
	return;
}

// Export UCharacterAttackAction::execCanTargetHitUs(FFrame&, void* const)
native function bool CanTargetHitUs();

// Export UCharacterAttackAction::execFindAvoidancePoint(FFrame&, void* const)
native function FindAvoidancePoint();

// Export UCharacterAttackAction::execStopHangingOut(FFrame&, void* const)
native function StopHangingOut();

// Export UCharacterAttackAction::execSetAvoidanceTimeout(FFrame&, void* const)
native function SetAvoidanceTimeout();

// Export UCharacterAttackAction::execStopMovingToAvoidancePoint(FFrame&, void* const)
native function StopMovingToAvoidancePoint();

// Export UCharacterAttackAction::execCheckIfShouldMoveToAvoidancePoint(FFrame&, void* const)
native function CheckIfShouldMoveToAvoidancePoint();

event NotifyMovingToAvoidancePoint()
{
	return;
}

function bool ShouldStopMovingToTarget()
{
	return __NFUN_132__(IsAttackingTarget(), InternalCanAttackTarget());
	return;
}

function bool GetRotationToTarget(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(Target.Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredFocalPointOverride(out Vector DesiredFocalPoint)
{
	return false;
	return;
}

function bool GetDesiredRotationOverride(out Rotator DesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xC2
	/*@Error*/
	// End:0x5B
	if(InternalCanAttackTarget())
	{
		DesiredRotation = Rotator(__NFUN_216__(Target.Location, m_Pawn.Location));
		return true;
		goto J0xC2;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC2
		/*@Error*/
	}
	DesiredRotation = Rotator(__NFUN_216__(Target.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function GetUpdatedDestination(out Actor outDestinationActor, out Vector outDestinationLocation)
{
	// End:0x25
	if(__NFUN_119__(MoveToActor, none))
	{
		outDestinationActor = MoveToActor;
		goto J0x38;
		outDestinationLocation = MoveToPoint;
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnMoveStarted()
{
	return;
}

function OnMoveEnded()
{
	// End:0x3C
	if(__NFUN_130__(bMovingToAvoidancePoint, m_Pawn.ReachedDestination(MoveToActor)))
	{
		OnReachedAvoidancePoint();
		StopMovingToAvoidancePoint();
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
}

protected function OnReachedAvoidancePoint()
{
	SetAvoidanceTimeout();
	return;
}

function OnTurnStarted()
{
	return;
}

function OnTurnEnded()
{
	return;
}

function NotifyCannotFindWayToDestination()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5E
	/*@Error*/
	EcologyFighter(m_Pawn).AddUnreachableTarget(Target);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyFoundWayToDestination()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5E
	/*@Error*/
	EcologyFighter(m_Pawn).RemoveUnreachableTarget(Target);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToAttack()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	// End:0x7B
	if(__NFUN_119__(MoveToActor, none))
	{
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
		construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, MoveToActor);
		goto J0xE3;
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location, true);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToTarget;
	CurrentMoveToGoal.__GetDesiredFocalPointOverride__Delegate = GetDesiredFocalPointOverride;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	CurrentMoveToGoal.__GetUpdatedDestination__Delegate = GetUpdatedDestination;
	CurrentMoveToGoal.__OnMoveStarted__Delegate = OnMoveStarted;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnMoveEnded;
	CurrentMoveToGoal.__OnTurnStarted__Delegate = OnTurnStarted;
	CurrentMoveToGoal.__OnTurnEnded__Delegate = OnTurnEnded;
	CurrentMoveToGoal.__NotifyCannotFindWayToDestination__Delegate = NotifyCannotFindWayToDestination;
	CurrentMoveToGoal.__NotifyFoundWayToDestination__Delegate = NotifyFoundWayToDestination;
	CurrentMoveToGoal.SetLocomotionResumeAlignmentThreshold(LocomotionResumeAlignmentThreshold);
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.SetShouldCutCorners(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetMovementBehavior()
{
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.SetMovementType(1, none, m_Pawn.Location);
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationOverride;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function FaceTarget()
{
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.SetMovementType(0, none, m_Pawn.Location);
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationToTarget;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD7
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0x5F;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function Actor OnPushGetPushee()
{
	return;
}

function bool ShouldPlayInitialReaction()
{
	local Actor ViewActor;
	local Vector ViewLocation;
	local Rotator ViewRotation;
	local Weapon PlayersActiveWeapon;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x102
	/*@Error*/
	PlayersActiveWeapon = Weapon(Target.GetActiveHoldable());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFD
	/*@Error*/
	PlayerController(Target.Controller).PlayerCalcView(ViewActor, ViewLocation, ViewRotation);
	return __NFUN_129__(PlayersActiveWeapon.CanHit(Target, ShockAI(), ViewLocation, ViewRotation));
	goto J0xFF;
	return false;
	goto J0x104;
	return true;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool HasBeenDamagedByTargetRecently(float RecentTime)
{
	local float LastTimeDamagedByTarget;

	return __NFUN_130__(m_Pawn.__NFUN_303__('EcologyFighter'), __NFUN_130__(EcologyFighter(m_Pawn).GetLastTimeDamagedByDamager(Target, LastTimeDamagedByTarget), __NFUN_178__(__NFUN_175__(m_Pawn.Level.TimeSeconds, LastTimeDamagedByTarget), RecentTime)));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function PlayInitialReaction()
{
	local name InitialReactionAnimationName;
	local bool bIsOnCeiling;

	bIsOnCeiling = m_Pawn.IsOnCeiling();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2AE
	/*@Error*/
	FaceTarget();
	// End:0x1E9
	if(m_Pawn.IsOnCeiling())
	{
		InitialReactionAnimationName = CeilingInitialReactionAnimations[__NFUN_167__(CeilingInitialReactionAnimations.Length)];
		goto J0x209;
		InitialReactionAnimationName = InitialReactionAnimations[__NFUN_167__(InitialReactionAnimations.Length)];
		InitialReactionAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, InitialReactionAnimationName);
		m_Pawn.FinishAnimation(InitialReactionAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x29A
		/*@Error*/
		EcologyFighter(Target).NotifyAboutToBeAttackedByAnotherAI(ShockAI());
		OnInitialReactionFinished();
	}
	ResetMovementBehavior();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

protected function OnInitialReactionFinished()
{
	return;
}

protected latent function NotifyBeginningAttack()
{
	return;
}

protected latent function NotifyGoingToStartAttacking()
{
	return;
}

protected latent function NotifyReadyToAttackTarget()
{
	StopMovingToAvoidancePoint();
	StopHangingOut();
	ShockAI().StopSpeech('TargetFled', true);
	ShockAI().StopSpeech('LostLOS', true);
	return;
}

protected latent function NotifyFinishedAttackingTarget()
{
	return;
}

protected latent function NotifyAttackCompleted()
{
	return;
}

function NotifyCannotAttackTarget()
{
	local float CurrentTime;
	local bool bCanSeeTarget;

	CurrentTime = Level().TimeSeconds;
	bCanSeeTarget = m_Pawn.CanSee(Target);
	// End:0x8C
	if(__NFUN_130__(IsTargetFleeing(), bCanSeeTarget))
	{
		ShockAI().PlaySpeech('TargetFled');
		goto J0xBC;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xBC
		/*@Error*/
		ShockAI().PlaySpeech('LostLOS');
	}
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function bool IsTargetFleeing()
{
	local Vector TargetVelocity;

	TargetVelocity = Target.GetVelocity();
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("IsTargetFleeing - VSizeSquared2D(TargetVelocity): ", string(VSizeSquared2D(TargetVelocity))), " Dot: "), string(__NFUN_177__(__NFUN_219__(__NFUN_226__(TargetVelocity), __NFUN_226__(__NFUN_216__(Target.Location, m_Pawn.Location))), 0.0000000))));
	return __NFUN_130__(__NFUN_177__(VSizeSquared2D(TargetVelocity), 0.0000000), __NFUN_177__(__NFUN_219__(__NFUN_226__(TargetVelocity), __NFUN_226__(__NFUN_216__(Target.Location, m_Pawn.Location))), 0.0000000));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function UseCurrentWeapon(AIWeapon CurrentWeapon)
{
	SendAttackEventNotification(CurrentWeapon);
	ShockAI(m_Pawn).BeginFiring();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x86
	/*@Error*/
	// End:0x79
	if(ShouldInterruptAttack(CurrentWeapon))
	{
		ShockAI(m_Pawn).StopAnyWeaponAction();
		goto J0x86;
		yield();
		// [Loop Continue]
		goto J0x33;
		return;
		@NULL
		EcologyAI
	}
	BioshockMovementAction
	@NULL
}

function SendAttackEventNotification(AIWeapon DesiredWeapon)
{
	local ShockAI AITarget;
	local DamageStimuliSet CurrentStimuliSet;
	local UsableWeaponAttackInfo WeaponAttackInfo;

	AITarget = ShockAI(Target);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10F
	/*@Error*/
	WeaponAttackInfo = DesiredWeapon.GetNextWeaponAttackInfo();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10F
	/*@Error*/
	CurrentStimuliSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(DesiredWeapon.static.GetCurrentAmmoSelection().default.DamageStimuliSetName);
	AITarget.HandleAIAttackNotification(m_Pawn, WeaponAttackInfo.AIAttackAnimationAttackTime, CurrentStimuliSet.GetDamageType());
	CurrentStimuliSet.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

latent function AttackTarget()
{
	return;
}

state Running
{Begin:

	waitForResourcesAvailable(achievingGoal.Priority, achievingGoal.Priority);
	useResources(Class'VengeanceShared.AI_Resource'.2);
	// End:0x9C
	if(__NFUN_132__(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Target)), __NFUN_129__(Target.CanBeAttacked())))
	{
		goto 'Finish';
		bWasAbleToAttackAtLastOpportunity = true;
		ShockAI().SetShouldRun();
		ShockAI().BecomeAggressive();
	}
	ShockAI().QuickLook(Target);
	NotifyBeginningAttack();
	// End:0x150
	if(__NFUN_132__(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Target)), __NFUN_129__(Target.CanBeAttacked())))
	{
		goto 'Finish';
		MoveToAttack();
		PlayInitialReaction();
		// End:0x1B1
		if(__NFUN_132__(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Target)), __NFUN_129__(Target.CanBeAttacked())))
		{
		}
		goto 'Finish';
		NotifyGoingToStartAttacking();
		// End:0x208
		if(__NFUN_132__(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Target)), __NFUN_129__(Target.CanBeAttacked())))
		{
			goto 'Finish';
			LoopStartTime = Level().TimeSeconds;
		}
		ShockAI().QuickLook(Target);
		// End:0x38F
		if(__NFUN_130__(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(Target), __NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp())), __NFUN_129__(InternalCanAttackTarget())))
		{
		}
		log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " yield 5 - CanAttackTarget(): "), string(CanAttackTarget())), " class'Pawn'.static.checkAlive(Target): "), string(Class'Engine.Pawn'.static.checkAlive(Target))));
		ShockAI().QuickLook(Target);
		CheckShouldDodge();
		NotifyCannotAttackTarget();
		yield();
		// [Loop Continue]
		goto J0x24A;
		// End:0x4B8
		if(__NFUN_130__(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(Target), __NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp())), InternalCanAttackTarget()))
		{
			LastTimeCouldAttack = Level().TimeSeconds;
			ShockAI().QuickLook(Target);
			NotifyReadyToAttackTarget();
			TriggerTaunt();
			// End:0x49F
			if(__NFUN_132__(__NFUN_180__(LastTimeCouldAttack, Level().TimeSeconds), InternalCanAttackTarget()))
			{
			}
			bWasAbleToAttackAtLastOpportunity = true;
			AttackTarget();
			CheckShouldDodge();
			NotifyFinishedAttackingTarget();
			goto J0x4AB;
			bWasAbleToAttackAtLastOpportunity = false;
			yield();
			// [Loop Continue]
			goto J0x38F;
			// End:0x528
			if(__NFUN_130__(__NFUN_130__(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()), Class'Engine.Pawn'.static.checkAlive(Target)), Target.CanBeAttacked()))
			{
				goto 'Loop';
				log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " finished attacking target at "), string(Level().TimeSeconds)), " GetAttackTarget: "), string(ShockAI().GetAttackTarget())));
			}
		}
		NotifyAttackCompleted();
		succeed();
		stop;		
		@NULL
		@NULL
		@NULL
		@NULL
	}
Finish:


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 834
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:Switch Position:0x531
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 834
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x531
}

defaultproperties
{
	InitialReactionIgnoreDamageTime=5.0000000
	AttackBehaviorAllowedYawRotationErrorTwoByte=910
	HangoutTimeRange=(Min=5.0000000,Max=15.0000000)
	ChanceToMoveAwayUponHearingFootsteps=0.2500000
	MinDistanceToMoveAwayUponHearingFootsteps=500.0000000
	MinDistanceToMoveAwayForLineOfSight=1000.0000000
	MinDistanceToMoveOut=100.0000000
	UnreachableTimeBeforeAvoidingTarget=0.5000000
	MinDistanceToTargetWhileAvoiding=100.0000000
	MinDistanceToMoveWhileAvoiding=100.0000000
	AvoidUpdateAvoidancePointTime=0.2500000
	CombatTauntDelay=(Min=8.0000000,Max=12.0000000)
	MeleeInterruptDegrees=180.0000000
	LocomotionResumeAlignmentThreshold=0.5000000
	satisfiesGoal=Class'ShockAI.AttackTargetGoal'
	bExclusiveAction=true
}