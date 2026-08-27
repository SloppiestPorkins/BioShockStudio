class Protector extends EcologyFighter implements ICanBeControlled
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

enum EDispositionToPlayer
{
	kNoDispositionToPlayer,         // 0
	kHostileToPlayer,               // 1
	kFriendlyToPlayer               // 2
};

enum EThreatenPlayerState
{
	kNoThreatenPlayerState,         // 0
	kLevel_1,                       // 1
	kLevel_2,                       // 2
	kLevel_3                        // 3
};

var private Gatherer CurrentGatherer;
var private GathererVent CurrentVent;
var const array<name> StartSpawnZones;
var private GathererVent NextGathererVent;
var private name NextGathererLabel;
var private bool bIsGuardingProtector;
var const Range GuardProtectorRange;
var private bool bShouldPickUpGatherer;
var private bool bCanPickUpGatherer;
var private Vector GathererJumpUpPoint;
var private float NextTimeCanPickUpGatherer;
var private Protector.EDispositionToPlayer DispositionToPlayer;
var private bool bProtectingPlayer;
var private float EndProtectingPlayerTime;
var private config float ProtectingPlayerTimeOutWarning;
var private bool HasWarnedAboutProtectingPlayerTimeoutYet;
var private float LastTimeFinishedThreateningPlayer;
var private Protector.EThreatenPlayerState ThreatenPlayerState;
var private ShockPawn LastThreatenTarget;
var private float LastTimeMovedTargetOutOfTheWay;
var private ShockPawn MoveOutOfTheWayTarget;
var private config float MaxDistanceFromGathererWhileSearching;
var private config float DistanceToPickUpGatherer;
var private config float DistanceGathererWillJumpOff;
var private config float HeightGathererWillJumpOff;
var private config float PlayerResetThreatenTime;
var private config float TimeBetweenPushingPlayer;
var private config float DistanceFromTargetToMoveOutOfTheWay;
var private config float MinTimeBetweenMovingTargetOutOfTheWay;
var private config float MinDotProductToMoveTargetOutOfTheWay;
var private config name MoveTargetOutOfTheWayAnimation;
var private config name InitialBashPlayerEffectEvent;
var private config name SecondBashPlayerEffectEvent;
var private config name FinalBashPlayerEffectEvent;
var config array<name> ThreatenAnimations;
var config array<name> FinalThreatAnimations;
var config array<name> BeginPrepareVentAnimations;
var config array<name> LoopPrepareVentAnimations;
var config array<name> EndPrepareVentAnimations;
var config array<name> GathererPreEnterAnimations;
var config array<name> HelpGathererIntoVentAnimations;
var config array<name> HelpGathererOutOfVentAnimations;
var config array<name> InitialCallVentAnimations;
var config array<name> SecondaryCallVentAnimations;
var config array<name> WaitingForGathererGestureAnimations;
var config array<name> SubsequentWaitingForGathererGestureAnimations;
var config array<name> BashTargetAnimations;
var config array<name> InitialBashPlayerAnimations;
var config array<name> SecondBashPlayerAnimations;
var config array<name> FinalBashPlayerAnimations;
var config array<name> MournGathererAnimations;
var config array<name> GathererDeathReactionAnimations;
var config array<name> ComeOnTiredGathererAnimations;
var config array<name> FrustratedAtTiredGathererAnimations;
var config array<name> SynchedUnevenSurfaceTiredGathererAnimations;
var config array<name> SynchedEvenSurfaceTiredGathererAnimations;
var config array<name> SynchedUnevenSurfaceTiredAnimations;
var config array<name> SynchedEvenSurfaceTiredAnimations;
var config array<name> PickUpGathererAnimations;
var config array<name> GathererPickedUpAnimations;
var config array<name> GathererJumpOffAnimations;
var config array<name> ReleaseGathererAnimations;
var config array<name> StunnedGathererLoopingAnimations;
var config array<name> ScreamAnimations;
var config array<name> WaitToPickUpGathererAnimations;
var private config name TransitionToAggressiveAnimation;
var private config name TransitionToIdleAnimation;
var private config name GathererAttachedBoneName;
var private config float TimeBetweenPickingUpGatherer;
var private config name MoveAIStimuliSetName;

function PreLevelTravel()
{
	super.PreLevelTravel();
	// End:0x43
	if(__NFUN_130__(IsAlive(), __NFUN_119__(CurrentGatherer, none)))
	{
		CurrentGatherer.__NFUN_279__();
		CurrentGatherer = none;
		CurrentVent = none;
		return;
		@NULL
		CommanderAction
	}
	stop;
	default.@NULL
}

function Destroyed()
{
	// End:0x17
	if(bProtectingPlayer)
	{
		EndProtectingPlayer();
		super(ShockAI).Destroyed();
	}
	return;
	@NULL
	CommanderAction
}

// Export UProtector::execIsMoveOutOfTheWayTargetWithinRange(FFrame&, void* const)
native function bool IsMoveOutOfTheWayTargetWithinRange();

function Actor GetPusheeFromPush()
{
	local Vector DirectionToTarget, OffsetToTarget;
	local DamageStimuliSet DamageSet;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x12A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11D
	/*@Error*/
	OffsetToTarget = __NFUN_216__(MoveOutOfTheWayTarget.Location, Location);
	DirectionToTarget = __NFUN_226__(OffsetToTarget);
	DamageSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(MoveAIStimuliSetName);
	ShockAI(MoveOutOfTheWayTarget).Fall(MoveOutOfTheWayTarget.Location, __NFUN_211__(DirectionToTarget), DirectionToTarget, 0.0000000, 'None', 'None', DamageSet);
	DamageSet.__NFUN_200__();
	return MoveOutOfTheWayTarget;
	goto J0x140;
	MoveOutOfTheWayTarget = none;
	return super(ShockPawn).GetPusheeFromPush();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnAcquiredState(name StateName, Actor Instigator)
{
	local ShockPawn ShockPawnInstigator;

	super(ShockAI).OnAcquiredState(StateName, Instigator);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	ShockPawnInstigator = ShockPawn(Instigator);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	AddForcedEnemy(ShockPawnInstigator);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	// End:0x17
	if(bProtectingPlayer)
	{
		EndProtectingPlayer();
		super(ShockAI).OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	}
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnDamaged(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	local ShockPlayer Player;
	local ShockPlayerController PlayerController;

	super(ShockAI).OnDamaged(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x327
	/*@Error*/
	// End:0x26B
	if(DamageStimuli.HasDamageStimulusType(34))
	{
		Player = ShockPlayer(Damager);
		PlayerController = ShockPlayerController(Player.Controller);
		assert(__NFUN_119__(Player, none));
		// End:0x268
		if(Class'Engine.Pawn'.static.checkAlive(Player))
		{
			// End:0x1F5
			if(__NFUN_130__(__NFUN_129__(IsProtectingPlayer()), __NFUN_132__(__NFUN_129__(Player.CanHaveMoreProtectorControllables()), IsEnemy(Player))))
			{
				TriggerEffectEvent('SummonProtectorFailed', none, none, HitLocation, Rotator(HitNormal));
				// End:0x1BF
				if(IsEnemy(Player))
				{
					PlayerController.GetPlayerStatsManager().BefriendUsed("AlreadyEnemy");
					goto J0x1F2;
					PlayerController.GetPlayerStatsManager().BefriendUsed("HasProtector");
					goto J0x268;
					TriggerEffectEvent('SummonProtectorSucceeded', none, none, HitLocation, Rotator(HitNormal));
					BeginProtectingPlayer(ShockPlayer(Damager));
					PlayerController.GetPlayerStatsManager().BefriendUsed("Success");
				}
				goto J0x327;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x2BB
				/*@Error*/
			}
			EndProtectingPlayer();
			goto J0x327;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x327
			/*@Error*/
			AddForcedEnemy(InsectSwarm(Damager).SwarmPlayerOwner);
		}
	}
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function BeginProtectingPlayer(ShockPlayer PlayerToProtect)
{
	local bool bWasAlreadyProtectingPlayer;

	bWasAlreadyProtectingPlayer = bProtectingPlayer;
	bProtectingPlayer = true;
	EndProtectingPlayerTime = PlayerToProtect.ModifyStat('ProtectPlayerTime_Bonus', Level.TimeSeconds);
	HasWarnedAboutProtectingPlayerTimeoutYet = false;
	// End:0xA3
	if(bWasAlreadyProtectingPlayer)
	{
		TriggerEffectEvent('FriendlyToPlayer');
		UnTriggerEffectEvent('BecomingUnFriendlyToPlayer');
		goto J0xCE;
		GetProtectorCommanderAction().BeginProtectingPlayer(PlayerToProtect);
		BecomeFriendlyTowardsPlayer();
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function EndProtectingPlayer()
{
	local ShockPlayer Player;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x9D
	/*@Error*/
	bProtectingPlayer = false;
	GetProtectorCommanderAction().EndProtectingPlayer();
	UnTriggerEffectEvent('BecomingUnFriendlyToPlayer');
	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9D
	/*@Error*/
	ResetDispositionToPlayer();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool IsProtectingPlayer()
{
	return bProtectingPlayer;
	return;
	@NULL
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x24
	if(__NFUN_130__(IsAlive(), __NFUN_129__(IsProtectingPlayer())))
	{
		return 2;		
	}
	else
	{
		// End:0x37
		if(CanBeUsedNow())
		{
			return 1;			
		}
		else
		{
			return 0;
		}
	}
	return;
}

function AddInitialKeywords()
{
	super(ShockAI).AddInitialKeywords();
	AddLocomotionKeyword('SlowWalk', -1);
	AddLocomotionKeyword('Guarding', -1);
	AddLocomotionKeyword('WaitingForGatherer', -1);
	return;
	@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.ProtectorCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.CharacterMoveToAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ThreatenAction');
	CharacterAI.addAbility_Class(Class'ShockAI.EscortAction');
	CharacterAI.addAbility_Class(Class'ShockAI.WaitForGathererAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ReactToGathererDeathAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ReactToTiredGathererAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ReactToStunnedGathererAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ProtectPlayerAction');
	CharacterAI.addSensorActionClass(Class'ShockAI.AlertSensorAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function MovementAICreated()
{
	super(ShockAI).MovementAICreated();
	MovementAI.addAbility_Class(Class'ShockAI.MoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

// Export UProtector::execGetProtectorCommanderAction(FFrame&, void* const)
native function ProtectorCommanderAction GetProtectorCommanderAction();

function OnAttackTargetReset(ShockPawn Target)
{
	super.OnAttackTargetReset(Target);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5E
	/*@Error*/
	EndProtectingPlayer();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function BecomeHostileTowardsPlayer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x59
	/*@Error*/
	DispositionToPlayer = 1;
	UnTriggerEffectEvent('NeutralToPlayer');
	UnTriggerEffectEvent('FriendlyToPlayer');
	TriggerEffectEvent('HostileToPlayer');
	return;
	@NULL
	CommanderAction
}

function BecomeFriendlyTowardsPlayer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x46
	/*@Error*/
	DispositionToPlayer = 2;
	UnTriggerEffectEvent('NeutralToPlayer');
	TriggerEffectEvent('FriendlyToPlayer');
	return;
	@NULL
	CommanderAction
}

function ResetDispositionToPlayer()
{
	DispositionToPlayer = 0;
	UnTriggerEffectEvent('FriendlyToPlayer');
	UnTriggerEffectEvent('HostileToPlayer');
	UnTriggerEffectEvent('NeutralToPlayer');
	TriggerEffectEvent('NeutralToPlayer');
	return;
	@NULL
}

function bool IsGuardingProtector()
{
	return bIsGuardingProtector;
	return;
	@NULL
}

function SetCurrentGatherer(Gatherer NewGatherer)
{
	assert(__NFUN_132__(__NFUN_114__(CurrentGatherer, none), __NFUN_114__(NewGatherer, none)));
	CurrentGatherer = NewGatherer;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Gatherer GetCurrentGatherer()
{
	return CurrentGatherer;
	return;
	@NULL
}

function SetCurrentVent(GathererVent inGathererVent)
{
	assert(__NFUN_119__(inGathererVent, none));
	CurrentVent = inGathererVent;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function GathererVent GetCurrentVent()
{
	return CurrentVent;
	return;
	@NULL
}

function GathererVent GetNextGathererVent()
{
	return NextGathererVent;
	return;
	@NULL
}

function ResetAttackTargets()
{
	// End:0x28
	if(__NFUN_119__(GetProtectorCommanderAction(), none))
	{
		GetProtectorCommanderAction().ResetAttackTargets();
	}
	return;
}

function SetNextGathererVent(GathererVent inNextGathererVent)
{
	// End:0x25
	if(__NFUN_119__(inNextGathererVent, none))
	{
		NextGathererVent = inNextGathererVent;
		goto J0x9D;
		log('AI', 3, __NFUN_112__(string(Name), " SetNextGathererVent was told to set the next vent to an invalid Actor, ignoring request."));
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ClearNextVent()
{
	NextGathererVent = none;
	return;
	@NULL
}

function name GetNextGathererLabel()
{
	return NextGathererLabel;
	return;
	@NULL
}

function SetNextGathererLabel(name inNextGathererLabel)
{
	// End:0x2A
	if(__NFUN_255__(inNextGathererLabel, 'None'))
	{
		NextGathererLabel = inNextGathererLabel;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function ClearNextGathererLabel()
{
	NextGathererLabel = 'None';
	return;
	@NULL
}

function NotifyGathererExitingVent()
{
	GetProtectorCommanderAction().NotifyGathererExitingVent();
	return;
}

function NotifyGathererStartingToFeed()
{
	GetProtectorCommanderAction().NotifyGathererStartingToFeed();
	return;
}

function NotifyGathererFeedingInterrupted()
{
	GetProtectorCommanderAction().NotifyGathererFeedingInterrupted();
	return;
}

function NotifyGathererFinishedFeeding()
{
	GetProtectorCommanderAction().NotifyGathererFinishedFeeding();
	return;
}

function NotifyThreatenTarget(ShockPawn ThreatenTarget)
{
	GetProtectorCommanderAction().NotifyThreatenTarget(ThreatenTarget);
	return;
	@NULL
}

function NotifyRemoveThreatenTarget(ShockPawn FormerThreatenTarget)
{
	GetProtectorCommanderAction().NotifyRemoveThreatenTarget(FormerThreatenTarget);
	return;
	@NULL
}

function NotifyEscortedGathererDamaged(Gatherer DamagedGatherer, Actor Damager)
{
	assert(__NFUN_119__(DamagedGatherer, none));
	GetProtectorCommanderAction().NotifyEscortedGathererDamaged(DamagedGatherer, Damager);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function NotifyGathererPlayingPreEnterAnimation()
{
	GetProtectorCommanderAction().NotifyGathererPlayingPreEnterAnimation();
	return;
}

function NotifyGathererReadyToEnterVent()
{
	GetProtectorCommanderAction().NotifyGathererReadyToEnterVent();
	return;
}

function NotifyGathererLookingAtTarget()
{
	GetProtectorCommanderAction().NotifyGathererLookingAtTarget();
	return;
}

function NotifyGathererFinishedLookingAtTarget()
{
	GetProtectorCommanderAction().NotifyGathererFinishedLookingAtTarget();
	return;
}

function NotifyReactToTiredGatherer()
{
	GetProtectorCommanderAction().NotifyReactToTiredGatherer();
	return;
}

function NotifyGathererJumpingOff()
{
	GetProtectorCommanderAction().NotifyGathererJumpingOff();
	return;
}

function NotifyGathererStunned()
{
	GetProtectorCommanderAction().NotifyGathererStunned();
	return;
}

function NotifyGathererNoLongerStunned()
{
	GetProtectorCommanderAction().NotifyGathererNoLongerStunned();
	return;
}

function bool IsSafeForGathererToJumpOff(Gatherer TestGatherer)
{
	local Vector TestPoint;

	assert(Class'Engine.Pawn'.static.checkAlive(TestGatherer));
	TestPoint = __NFUN_215__(TestGatherer.Location, __NFUN_212__(Vector(Rotation), DistanceGathererWillJumpOff));
	__NFUN_185__(TestPoint.Z, HeightGathererWillJumpOff);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10C
	/*@Error*/
	return true;
	goto J0x10E;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsGathererAttached()
{
	local int i;

	i = __NFUN_147__(Attached.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5C
	/*@Error*/
	// End:0x4E
	if(Attached[i].__NFUN_303__('Gatherer'))
	{
		return true;
		__NFUN_164__(i);
		// [Loop Continue]
		goto J0x17;
		return false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function SetShouldPickUpGatherer(bool inShouldPickUpGatherer, optional Vector inGathererJumpUpPoint)
{
	bShouldPickUpGatherer = inShouldPickUpGatherer;
	GathererJumpUpPoint = inGathererJumpUpPoint;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldPickUpGatherer()
{
	return bShouldPickUpGatherer;
	return;
	@NULL
}

function float GetDistanceToPickUpGatherer()
{
	return DistanceToPickUpGatherer;
	return;
	@NULL
}

function Vector GetGathererJumpUpPoint()
{
	return GathererJumpUpPoint;
	return;
	@NULL
}

function bool CanPickUpGatherer()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(bCanPickUpGatherer, __NFUN_177__(Level.TimeSeconds, NextTimeCanPickUpGatherer)), __NFUN_129__(IsBerserk())), __NFUN_129__(IsFrozen())), __NFUN_129__(IsShocked())), __NFUN_129__(IsBurning())), __NFUN_129__(IsBeingAttackedByInsectSwarm()));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetCanPickUpGatherer(bool inCanPickUpGatherer)
{
	bCanPickUpGatherer = inCanPickUpGatherer;
	return;
	@NULL
	CommanderAction
}

function SetNextTimeCanPickUpGatherer()
{
	NextTimeCanPickUpGatherer = __NFUN_174__(Level.TimeSeconds, TimeBetweenPickingUpGatherer);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ShockPawn GetLastThreatenTarget()
{
	return LastThreatenTarget;
	return;
	@NULL
}

function SetLastThreatenTarget(ShockPawn inLastThreatenTarget)
{
	LastThreatenTarget = inLastThreatenTarget;
	return;
	@NULL
	CommanderAction
}

function name GetThreatenAnimationName()
{
	return ThreatenAnimations[__NFUN_167__(ThreatenAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetFinalThreatAnimationName()
{
	return FinalThreatAnimations[__NFUN_167__(FinalThreatAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetBeginPrepareVentAnimationName()
{
	return BeginPrepareVentAnimations[__NFUN_167__(BeginPrepareVentAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetLoopPrepareVentAnimationName()
{
	return LoopPrepareVentAnimations[__NFUN_167__(LoopPrepareVentAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetEndPrepareVentAnimationName()
{
	return EndPrepareVentAnimations[__NFUN_167__(EndPrepareVentAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetGathererPreEnterAnimationName()
{
	return GathererPreEnterAnimations[__NFUN_167__(GathererPreEnterAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetHelpGathererIntoVentAnimationName()
{
	return HelpGathererIntoVentAnimations[__NFUN_167__(HelpGathererIntoVentAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetHelpGathererOutOfVentAnimationName()
{
	return HelpGathererOutOfVentAnimations[__NFUN_167__(HelpGathererOutOfVentAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetInitialCallVentAnimationName()
{
	return InitialCallVentAnimations[__NFUN_167__(InitialCallVentAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetSecondaryCallVentAnimationName()
{
	return SecondaryCallVentAnimations[__NFUN_167__(SecondaryCallVentAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetWaitingForGathererGestureAnimationName()
{
	return WaitingForGathererGestureAnimations[__NFUN_167__(WaitingForGathererGestureAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetSubsequentWaitingForGathererGestureAnimationName()
{
	return SubsequentWaitingForGathererGestureAnimations[__NFUN_167__(SubsequentWaitingForGathererGestureAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetBashTargetAnimationName(ShockPawn ThreatenTarget)
{
	assert(__NFUN_119__(ThreatenTarget, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9E
	/*@Error*/
	// End:0x59
	if(__NFUN_154__(int(ThreatenPlayerState), int(0)))
	{
		return InitialBashPlayerAnimations[__NFUN_167__(InitialBashPlayerAnimations.Length)];
		goto J0x9E;
		// End:0x87
		if(__NFUN_154__(int(ThreatenPlayerState), int(1)))
		{
			return SecondBashPlayerAnimations[__NFUN_167__(SecondBashPlayerAnimations.Length)];
		}
		goto J0x9E;
		return FinalBashPlayerAnimations[__NFUN_167__(FinalBashPlayerAnimations.Length)];
		return BashTargetAnimations[__NFUN_167__(BashTargetAnimations.Length)];
		return;
	}
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function name GetMournGathererAnimationName()
{
	return MournGathererAnimations[__NFUN_167__(MournGathererAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetGathererDeathReactionAnimation()
{
	return GathererDeathReactionAnimations[__NFUN_167__(GathererDeathReactionAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetTransitionIntoAggressiveName()
{
	return TransitionToAggressiveAnimation;
	return;
	@NULL
}

function name GetTransitionIntoIdleName()
{
	return TransitionToIdleAnimation;
	return;
	@NULL
}

function name GetComeOnTiredGathererAnimation()
{
	return ComeOnTiredGathererAnimations[__NFUN_167__(ComeOnTiredGathererAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetFrustratedAtTiredGathererAnimationName()
{
	return FrustratedAtTiredGathererAnimations[__NFUN_167__(FrustratedAtTiredGathererAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetSynchedTiredAnimationForGatherer(bool bUseUnevenSurfaceAnimation)
{
	// End:0x27
	if(bUseUnevenSurfaceAnimation)
	{
		return SynchedUnevenSurfaceTiredGathererAnimations[__NFUN_167__(SynchedUnevenSurfaceTiredGathererAnimations.Length)];
		goto J0x3E;
		return SynchedEvenSurfaceTiredGathererAnimations[__NFUN_167__(SynchedEvenSurfaceTiredGathererAnimations.Length)];
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function name GetSynchedTiredAnimation(bool bUseUnevenSurfaceAnimation)
{
	// End:0x27
	if(bUseUnevenSurfaceAnimation)
	{
		return SynchedUnevenSurfaceTiredAnimations[__NFUN_167__(SynchedUnevenSurfaceTiredAnimations.Length)];
		goto J0x3E;
		return SynchedEvenSurfaceTiredAnimations[__NFUN_167__(SynchedEvenSurfaceTiredAnimations.Length)];
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function name GetPickUpGathererAnimation()
{
	return PickUpGathererAnimations[__NFUN_167__(PickUpGathererAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetGathererPickedUpAnimation()
{
	return GathererPickedUpAnimations[__NFUN_167__(GathererPickedUpAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetGathererJumpOffAnimation()
{
	return GathererJumpOffAnimations[__NFUN_167__(GathererJumpOffAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetReleaseGathererAnimations()
{
	return ReleaseGathererAnimations[__NFUN_167__(ReleaseGathererAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetStunnedGathererLoopingAnimation()
{
	return StunnedGathererLoopingAnimations[__NFUN_167__(StunnedGathererLoopingAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetScreamAnimation()
{
	return ScreamAnimations[__NFUN_167__(ScreamAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function name GetWaitToPickUpGathererAnimation()
{
	return WaitToPickUpGathererAnimations[__NFUN_167__(WaitToPickUpGathererAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function bool ShouldRunWhileInvestigating()
{
	return true;
	return;
}

function float GetMaxDistanceFromGathererWhileSearching()
{
	return MaxDistanceFromGathererWhileSearching;
	return;
	@NULL
}

function bool IsSuspectingAttackFrom(ShockPawn Target)
{
	return __NFUN_130__(IsAlive(), GetProtectorCommanderAction().IsSuspectingAttackFrom(Target));
	return;
	@NULL
}

function NotifyStartingThreatenBehavior()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3B
	/*@Error*/
	ThreatenPlayerState = 0;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetLastTimeFinishedThreateningPlayer()
{
	LastTimeFinishedThreateningPlayer = Level.TimeSeconds;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function RampUpThreatenPlayerState()
{
	// End:0x23
	if(__NFUN_154__(int(ThreatenPlayerState), int(0)))
	{
		ThreatenPlayerState = 1;
		goto J0x52;
		// End:0x46
		if(__NFUN_154__(int(ThreatenPlayerState), int(1)))
		{
		}
		ThreatenPlayerState = 2;
		goto J0x52;
		ThreatenPlayerState = 3;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function bool ShouldAttackThreateningPlayer()
{
	return __NFUN_154__(int(ThreatenPlayerState), int(3));
	return;
	@NULL
}

function float GetTimeBetweenPushingPlayer()
{
	return TimeBetweenPushingPlayer;
	return;
	@NULL
}

function OnSpecialPushPlayer(ShockPlayer Player)
{
	local name EffectEventName;

	// End:0x2A
	if(__NFUN_154__(int(ThreatenPlayerState), int(0)))
	{
		EffectEventName = InitialBashPlayerEffectEvent;
		goto J0x67;
		// End:0x54
		if(__NFUN_154__(int(ThreatenPlayerState), int(1)))
		{
		}
		EffectEventName = SecondBashPlayerEffectEvent;
		goto J0x67;
		EffectEventName = FinalBashPlayerEffectEvent;
		Player.OnPushed(EffectEventName, self);
	}
	return;
	@NULL
	J0x67:

	CommanderAction
	CommanderAction
	@NULL
}

function InvestigatePlayer(ShockPlayer Player)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x31
	/*@Error*/
	GetProtectorCommanderAction().InvestigatePlayer(Player);
	return;
	@NULL
}

function NotifyAttackDamagerOfPerceivedGatherer(ShockPawn Damager)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x31
	/*@Error*/
	GetProtectorCommanderAction().NotifyAttackDamagerOfPerceivedGatherer(Damager);
	return;
	@NULL
}

function OnRegistered(ShockPawn Registerer)
{
	return;
}

function OnUnregistered(ShockPawn Registerer)
{
	return;
}

function OnControllerKilled(ShockPawn Controller)
{
	EndProtectingPlayer();
	return;
}

function OnControllerDestroyed(ShockPawn Controller)
{
	EndProtectingPlayer();
	return;
}

function OnControllerDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	// End:0x42
	if(__NFUN_130__(__NFUN_119__(Damager, self), __NFUN_129__(Damager.__NFUN_303__('Gatherer'))))
	{
		AddForcedEnemy(Damager);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnControllerDealtDamage(ShockPawn Damagee, float TotalDamageDealt)
{
	// End:0x42
	if(__NFUN_130__(__NFUN_119__(Damagee, self), __NFUN_129__(Damagee.__NFUN_303__('Gatherer'))))
	{
		AddForcedEnemy(Damagee);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function AttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{
	// End:0x42
	if(__NFUN_130__(__NFUN_119__(Target, self), __NFUN_129__(Target.__NFUN_303__('Gatherer'))))
	{
		AddForcedEnemy(Target);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function SetSector(int Sector)
{
	return;
}

function int GetSector()
{
	return;
}

function OnBecamePassive()
{
	dispatchMessage(Class'ShockAI.MessageAIBecamePassive'.static.Allocate(self)., construct_ShockAI(self));
	return;
	@NULL
}

defaultproperties
{
	ProtectingPlayerTimeOutWarning=15.0000000
	PlayerResetThreatenTime=20.0000000
	DistanceFromTargetToMoveOutOfTheWay=150.0000000
	MinTimeBetweenMovingTargetOutOfTheWay=5.0000000
	MinDotProductToMoveTargetOutOfTheWay=0.5000000
	MoveAIStimuliSetName="ProtectorPushAIStimuliSet"
	MinSearchTime=15.0000000
	MaxSearchTime=30.0000000
	UnintentionalDamageAggroPercentage=0.0250000
	ChanceToDouseAttacking=0.0000000
	MaxDistanceToMoveToWater=1000.0000000
	NormalVisionDecayTime=1.0000000
	SearchingVisionDecayTime=1.0000000
	AttackingVisionDecayTime=1.0000000
	BerserkVisionDecayTime=1.0000000
	PatrolVisionDecayTime=1.0000000
	NormalVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	NormalVisionCones[1]=(NearGainTime=0.1000000,FarGainTime=0.3000000,FOV=120.0000000,NearDistance=2000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	SearchingVisionCones[1]=(NearGainTime=0.1500000,FarGainTime=0.4000000,FOV=110.0000000,NearDistance=2000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[2]=(NearGainTime=1.0000000,FarGainTime=2.0000000,FOV=150.0000000,NearDistance=800.0000000,FarDistance=2000.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	AttackingVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	AttackingVisionCones[1]=(NearGainTime=0.1000000,FarGainTime=0.1000000,FOV=180.0000000,NearDistance=1000.0000000,FarDistance=3500.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	AttackingVisionCones[2]=(NearGainTime=0.2000000,FarGainTime=0.2000000,FOV=180.0000000,NearDistance=1000.0000000,FarDistance=1000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=32768,Roll=0),PawnType=none)
	BerserkVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	BerserkVisionCones[1]=(NearGainTime=0.0100000,FarGainTime=0.0100000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	BurningTimeRange=(Min=2.0000000,Max=2.0000000)
	ShatteredDamageAmount=5000.0000000
	CriticalDamageEffectInfos=/* Array type was not detected. */
	DefaultDamageEventInfos=/* Array type was not detected. */
	AISourceDamageEventInfoOverrides=/* Array type was not detected. */
	CriticalHitDamageEvent=2
	PlayerSourceDamageEventInfoRanges=/* Array type was not detected. */
	PlayerSourceDamageEventInfoOverrides=/* Array type was not detected. */
	bVisionEnabled=true
	bHearingEnabled=true
	bHearingDisabledPermanently=false
}