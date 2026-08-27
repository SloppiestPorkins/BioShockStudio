class AssassinAttackAction extends AggressorAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private TeleportGoal CurrentTeleportGoal;
var private float LastTeleportTime;
var private int NumTimesAttacked;
var private int NumAttacksToCauseTeleport;
var private float MoveUntilTime;
var private bool bIsTeleporting;
var private float RangedWeaponDistance;
var private float NextTimeForFindPointToAttackTest;
var private bool bTeleportRunInDestinationSet;
var config float DistanceToUseBlastWeapon;
var config float MinDistanceToApproachTarget;
var config float MinDistanceToMoveForTeleport;
var config float MinDistanceToMoveForTeleportIn;
var config Range LocalDistanceRangeForTeleportIn;
var config Range LocalDistanceRangeForAttack;
var config float TeleportCannotAttackTime;
var config float TeleportDueToDamageTime;
var config float MaxTeleportTime;
var config Range NumAttacksToCauseTeleportRange;
var config float ChanceToTeleportInitially;
var config float AttackingMovementDelay;
var config float TeleportingMovementDelay;
var private config float MinTimeBetweenFindPointToAttackTests;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	RangedWeaponDistance = IProvideProjectileDamageData(ShockGameInfo(Level().Game).GetItemFromClass(GetRangedWeapon().GetDefaultAmmoSelection())).GetAttackRange();
	ResetNumAttacksToCauseTeleport();
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
	if(__NFUN_119__(CurrentTeleportGoal, none))
	{
		CurrentTeleportGoal.__NFUN_198__();
		CurrentTeleportGoal = none;
		ShockAI().SetAvoidTarget(none);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function goalAchievedCB(AI_Goal Goal, AI_Action Child)
{
	super(CharacterAttackAction).goalAchievedCB(Goal, Child);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	LastTimeCouldAttack = Level().TimeSeconds;
	NumTimesAttacked = 0;
	ResetNumAttacksToCauseTeleport();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UAssassinAttackAction::execShouldStopMovingToTarget(FFrame&, void* const)
native function bool ShouldStopMovingToTarget();

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

function bool CanTeleport()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_129__(IsDodging()), __NFUN_114__(CurrentTeleportGoal, none)), __NFUN_179__(__NFUN_175__(Level().TimeSeconds, LastTeleportTime), MaxTeleportTime));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldTeleportDueToDamage()
{
	local float LastDamagedTime;

	LastDamagedTime = ShockAI().GetLastTimeIntentionallyDamaged();
	return __NFUN_130__(__NFUN_177__(LastDamagedTime, LastTeleportTime), __NFUN_176__(__NFUN_175__(Level().TimeSeconds, LastDamagedTime), TeleportDueToDamageTime));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsTargetTooClose()
{
	return __NFUN_178__(VSizeSquared2D(__NFUN_216__(Target.Location, m_Pawn.Location)), __NFUN_171__(MinDistanceToApproachTarget, MinDistanceToApproachTarget));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool HasAttackedEnoughTimesToTeleport()
{
	return __NFUN_153__(NumTimesAttacked, NumAttacksToCauseTeleport);
	return;
	@NULL
	CommanderAction
}

function ResetNumAttacksToCauseTeleport()
{
	NumAttacksToCauseTeleport = int(RandRange(NumAttacksToCauseTeleportRange.Min, NumAttacksToCauseTeleportRange.Max));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Teleport()
{
	// End:0x73
	if(__NFUN_129__(ShockAI().FindPointToAvoidTarget(Target, MoveToActor, false, 0.0000000, 0.0000000, MinDistanceToMoveForTeleport, 0.0000000, true, MinDistanceToApproachTarget, true)))
	{
		MoveToPoint = m_Pawn.Location;
		bIsTeleporting = true;
		bCanDodgeWhileAttacking = false;
		assert(__NFUN_114__(CurrentTeleportGoal, none));
		LastTeleportTime = Level().TimeSeconds;
	}
	bTeleportRunInDestinationSet = false;
	CurrentTeleportGoal = Class'ShockAI.TeleportGoal'.static.Allocate(self).;
	construct_AI_ResourceActorBoolBoolRotatorBool(characterResource(), Target);
	CurrentTeleportGoal.__NFUN_199__();
	CurrentTeleportGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentTeleportGoal);
	CurrentTeleportGoal.unPostGoal(self);
	CurrentTeleportGoal.__NFUN_198__();
	CurrentTeleportGoal = none;
	MoveToPoint = m_Pawn.Location;
	MoveToActor = none;
	bIsTeleporting = false;
	bCanDodgeWhileAttacking = true;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

// Export UAssassinAttackAction::execCanAttackWithRangedWeapon(FFrame&, void* const)
native function bool CanAttackWithRangedWeapon();

// Export UAssassinAttackAction::execCanAttackTarget(FFrame&, void* const)
native function bool CanAttackTarget();

function AIRangedWeapon GetRangedWeapon()
{
	return Assassin(m_Pawn).GetRangedWeapon();
	return;
	@NULL
	CommanderAction
}

function NotifyGoingToStartAttacking()
{
	super.NotifyGoingToStartAttacking();
	// End:0x36
	if(__NFUN_130__(__NFUN_178__(__NFUN_195__(), ChanceToTeleportInitially), CanTeleport()))
	{
		Teleport();
		goto J0x57;
		LastTimeCouldAttack = Level().TimeSeconds;
	}
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function NotifyCannotAttackTarget()
{
	super(CharacterAttackAction).NotifyCannotAttackTarget();
	// End:0x62
	if(__NFUN_130__(__NFUN_132__(IsTargetTooClose(), __NFUN_177__(__NFUN_175__(Level().TimeSeconds, LastTimeCouldAttack), TeleportCannotAttackTime)), CanTeleport()))
	{
		Teleport();
		return;
		@NULL
		EcologyAI
		BioshockMovementAction
	}
	@NULL
}

function NotifyFinishedAttackingTarget()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x4D
	/*@Error*/
	__NFUN_163__(NumTimesAttacked);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D
	/*@Error*/
	Teleport();
	return;
	@NULL
}

function AttackTarget()
{
	local AIWeapon CurrentWeapon;

	CurrentWeapon = GetRangedWeapon();
	// End:0x6B
	if(__NFUN_119__(Assassin(m_Pawn).GetActiveHoldable(), CurrentWeapon))
	{
		Assassin(m_Pawn).Equip(CurrentWeapon);
		UseCurrentWeapon(CurrentWeapon);
		return;
		@NULL
		EcologyAI
		CommanderAction
	}
	@NULL
}

defaultproperties
{
	DistanceToUseBlastWeapon=400.0000000
	MinDistanceToApproachTarget=200.0000000
	MinDistanceToMoveForTeleport=500.0000000
	MinDistanceToMoveForTeleportIn=200.0000000
	LocalDistanceRangeForTeleportIn=(Min=75.0000000,Max=200.0000000)
	LocalDistanceRangeForAttack=(Min=75.0000000,Max=200.0000000)
	TeleportCannotAttackTime=3.0000000
	TeleportDueToDamageTime=5.0000000
	MaxTeleportTime=7.0000000
	NumAttacksToCauseTeleportRange=(Min=1.0000000,Max=1.0000000)
	MinTimeBetweenFindPointToAttackTests=0.5000000
	MimicAttackInfos[0]=(MimicPoseAnimationName="AS_PlayDeadBack_POSE",ForwardAttackAnimationName="AS_getUpBack_A",LeftAttackAnimationName="AS_getUpBack_A",RightAttackAnimationName="AS_getUpBack_A",BackwardAttackAnimationName="AS_getUpBack_A")
	MimicAttackInfos[1]=(MimicPoseAnimationName="AS_PlayDeadStomach_POSE",ForwardAttackAnimationName="AS_getUpStomach_A",LeftAttackAnimationName="AS_getUpStomach_A",RightAttackAnimationName="AS_getUpStomach_A",BackwardAttackAnimationName="AS_getUpStomach_A")
	MinCanTargetHitBeforeDodgeTime=0.1000000
	MinDodgeTime=4.0000000
	DodgeChance=0.7000000
	InitialReactionAnimations[0]="AS_Threaten_A"
	InitialReactionChance=1.0000000
}