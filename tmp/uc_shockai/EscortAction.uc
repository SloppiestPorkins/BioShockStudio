class EscortAction extends BioshockCharacterAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

enum EEscortedGathererState
{
	kMovingToBooty,                 // 0
	kFeedingAtBooty,                // 1
	kMovingToVent,                  // 2
	kPlayingPreEnterAnimation,      // 3
	kEnteringVent                   // 4
};

var private MoveToGoal CurrentMoveToGoal;
var private GathererVent GathererVent;
var private GathererVent LastUsedGathererVent;
var private bool bInsideMinDistance;
var private bool bOutsideWaitDistance;
var private bool bMournedGatherer;
var private bool bEscortingLinkedGatherer;
var private EscortAction.EEscortedGathererState CurrentGathererState;
var private Rotator CurrentFaceDirection;
var private ShockPawn CurrentGuardTarget;
var private Vector ProtectorLocationForGathererExit;
var private Vector ProtectorLocationForGathererEnter;
var private int VentRelatedAnimationHandle;
var private int HelpGathererEnterAnimationHandle;
var private int HelpGathererExitAnimationHandle;
var private int TransitionIntoStateAnimationHandle;
var private int MournAnimationHandle;
var private int ReleaseGathererAnimationHandle;
var private config float InitialCallVentSuccessChance;
var private config Range TimeRangeBeforeTurningAroundWhileGuarding;
var private config Range PauseWhileWaitingToDoSecondCallVentTime;
var private config Range DesiredVentRange;
var private config float DistanceForGathererToWait;
var private config float MinDistanceToGatherer;
var private config float MaxDistanceToGatherer;
var private config Range PauseWhileVisitingDeadGathererTime;
var private config name LookAtVisibleTargetBaseAnim;
var private config float MaxDistanceToLookAtNearbyVisibleTargetsWhileGuarding;
var private config float DistanceToVisitGatherer;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	return;
	@NULL
	CommanderAction
	CommanderAction
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
		if(m_Pawn.IsAnimationHandleValid(VentRelatedAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(VentRelatedAnimationHandle);
		// End:0xB9
		if(m_Pawn.IsAnimationHandleValid(TransitionIntoStateAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(TransitionIntoStateAnimationHandle);
		}
		// End:0xFC
		if(m_Pawn.IsAnimationHandleValid(MournAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(MournAnimationHandle);
			// End:0x12C
			if(__NFUN_119__(GathererVent, none))
			{
				GathererVent.ResetCurrentAI(ShockAI());
			}
			ShockAI().AddLocomotionKeyword('Guarding', Class'ShockAI.ShockAI'.-1);
			ShockAI().AddLocomotionKeyword('WaitingForGatherer', Class'ShockAI.ShockAI'.-1);
		}
		ShockAI().StopSpeech('Idling');
	}
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	ShockAI().bShouldApplyDisplacement = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetInternalState()
{
	local Gatherer CurrentGatherer;

	// End:0x30
	if(__NFUN_119__(GathererVent, none))
	{
		GathererVent.ResetCurrentAI(ShockAI());
		CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	}
	// End:0xB2
	if(__NFUN_130__(__NFUN_130__(__NFUN_119__(CurrentGatherer, none), __NFUN_129__(CurrentGatherer.bDeleteMe)), CurrentGatherer.ShouldSkipExit()))
	{
		bEscortingLinkedGatherer = true;
		goto J0xDF;
		Protector(m_Pawn).SetCurrentGatherer(none);
		bEscortingLinkedGatherer = false;
		// End:0x120
		if(__NFUN_119__(CurrentMoveToGoal, none))
		{
		}
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		LastUsedGathererVent = GathererVent;
		GathererVent = none;
		CurrentGathererState = 0;
		bMournedGatherer = false;
		bOutsideWaitDistance = false;
		ShockAI().SetShouldWalk();
		ShockAI().BecomePassive();
	}
	ShockAI().PlaySpeech('Idling');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	// End:0xF0
	if(__NFUN_129__(ShockAI().IsFrozen()))
	{
		// End:0x6A
		if(m_Pawn.IsAnimationHandleValid(VentRelatedAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(VentRelatedAnimationHandle);
			// End:0xAD
			if(m_Pawn.IsAnimationHandleValid(TransitionIntoStateAnimationHandle))
			{
				m_Pawn.SmartPerTrackEaseOutAnimation(TransitionIntoStateAnimationHandle);
			}
			// End:0xF0
			if(m_Pawn.IsAnimationHandleValid(MournAnimationHandle))
			{
				m_Pawn.SmartPerTrackEaseOutAnimation(MournAnimationHandle);
				// End:0x123
				if(ShockAI().IsAimingWeapon())
				{
				}
				ShockAI().StopAimingWeapon();
				ShockAI().AddLocomotionKeyword('Guarding', Class'ShockAI.ShockAI'.-1);
			}
		}
		ShockAI().AddLocomotionKeyword('WaitingForGatherer', Class'ShockAI.ShockAI'.-1);
	}
	ShockAI().StopSpeech('Idling');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	local Gatherer CurrentGatherer;

	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	CurrentGatherer = GetCurrentGatherer();
	// End:0x8F
	if(__NFUN_130__(__NFUN_129__(ShockAI().IsAttacking()), __NFUN_132__(__NFUN_132__(__NFUN_114__(CurrentGatherer, none), CurrentGatherer.IsAlive()), bMournedGatherer)))
	{
		ShockAI().BecomePassive();
		ShockAI().PlaySpeech('Idling');
	}
	ShockAI().SetShouldWalk();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Gatherer GetCurrentGatherer()
{
	return Protector(m_Pawn).GetCurrentGatherer();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererExitingVent()
{
	HelpGathererExitAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, Protector(m_Pawn).GetHelpGathererOutOfVentAnimationName());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererStartingToFeed()
{
	AssertWithDescription(__NFUN_132__(__NFUN_154__(int(CurrentGathererState), int(0)), __NFUN_154__(int(CurrentGathererState), int(1))), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " NotifyGathererStartingToFeed - CurrentGathererState ("), string(CurrentGathererState)), ") is not kMovingToBooty or kFeedingAtBooty"));
	CurrentGathererState = 1;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF1
	/*@Error*/
	CurrentMoveToGoal.SetShouldNeverSucceed(false);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererFeedingInterrupted()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x20
	/*@Error*/
	CurrentGathererState = 0;
	return;
	@NULL
	CommanderAction
}

function NotifyGathererFinishedFeeding()
{
	CurrentGathererState = 2;
	return;
	@NULL
}

function NotifyGathererPlayingPreEnterAnimation()
{
	AssertWithDescription(__NFUN_153__(int(CurrentGathererState), int(2)), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " NotifyGathererPlayingPreEnterAnimation - CurrentGathererState: ("), string(CurrentGathererState)), ") is not kMovingToVent"));
	CurrentGathererState = 3;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererReadyToEnterVent()
{
	local name HelpGathererIntoVentAnimation;
	local Vector ProtectorLocationForGathererEnter;
	local Rotator RotationAwayFromVent;

	AssertWithDescription(__NFUN_153__(int(CurrentGathererState), int(3)), __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " NotifyGathererReadyToExit - CurrentGathererState: ("), string(CurrentGathererState)), ") is not kPlayingPreEnterAnimation"));
	ProtectorLocationForGathererEnter = GathererVent.GetProtectorEnterLocation(Protector(m_Pawn));
	log('AI', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " 2D Distance to vent socket is: "), string(__NFUN_228__(__NFUN_216__(ProtectorLocationForGathererEnter, m_Pawn.Location)))));
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("Rotation away from vent: ", string(Rotator(__NFUN_216__(ProtectorLocationForGathererEnter, GathererVent.Location)))), " m_Pawn.Rotation: "), string(m_Pawn.Rotation)));
	// End:0x26A
	if(m_Pawn.ReachedLocation(ProtectorLocationForGathererEnter))
	{
		m_Pawn.__NFUN_267__(ProtectorLocationForGathererEnter);
		RotationAwayFromVent.Yaw = Rotator(__NFUN_216__(ProtectorLocationForGathererEnter, GathererVent.Location)).Yaw;
		m_Pawn.__NFUN_299__(RotationAwayFromVent);
		CurrentGathererState = 4;
		achievingGoal.changePriority(100);
		ShockAI().bDoNotTakeAnyDamage = true;
		m_Pawn.TriggerEffectEvent('BecameImmuneToFrozenState');
		ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
		HelpGathererIntoVentAnimation = Protector(m_Pawn).GetHelpGathererIntoVentAnimationName();
	}
	HelpGathererEnterAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, HelpGathererIntoVentAnimation);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyGathererThatWeAreAttacking(ShockPawn AttackTarget)
{
	// End:0x45
	if(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()))
	{
		GetCurrentGatherer().NotifyEscortIsAttacking(AttackTarget);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function NotifyGathererThatWeStoppedAttacking()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3C
	/*@Error*/
	GetCurrentGatherer().NotifyEscortStoppedAttacking();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererCaughtUp()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3C
	/*@Error*/
	GetCurrentGatherer().NotifyGathererProtectorCaughtUp();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererTooFarAway()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3C
	/*@Error*/
	GetCurrentGatherer().NotifyGathererThatProtectorIsTooFarAway();
	return;
	@NULL
	CommanderAction
}

function NotifyGathererJumpingOff()
{
	local name ReleaseGathererAnimation;

	achievingGoal.changePriority(100);
	ShockAI().bDoNotTakeAnyDamage = true;
	m_Pawn.TriggerEffectEvent('BecameImmuneToFrozenState');
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
	ReleaseGathererAnimation = Protector(m_Pawn).GetReleaseGathererAnimations();
	ReleaseGathererAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ReleaseGathererAnimation);
	Protector(m_Pawn).SetNextTimeCanPickUpGatherer();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetGathererVent()
{
	local bool bUsingScriptedVent;

	GathererVent = none;
	// End:0x15D
	if(__NFUN_114__(GathererVent, none))
	{
		GathererVent = Protector(m_Pawn).GetNextGathererVent();
		// End:0x60
		if(__NFUN_114__(GathererVent, none))
		{
			FindGathererVent();
			goto J0x6C;
			bUsingScriptedVent = true;
			// End:0x15A
			if(__NFUN_132__(__NFUN_114__(GathererVent, none), GathererVent.HasCurrentAI(ShockAI())))
			{
			}
			log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Could not find a usable GathererVent to move to, sleeping for 1 second! (CurrentVent AI: "), string(GathererVent.GetCurrentAI())), ")"));
			GathererVent = none;
			__NFUN_256__(1.0000000);
			// [Loop Continue]
			goto J0x0B;
			// End:0x18A
			if(bUsingScriptedVent)
			{
				Protector(m_Pawn).ClearNextVent();
				Protector(m_Pawn).SetCurrentVent(GathererVent);
			}
		}
		GathererVent.SetCurrentAI(ShockAI());
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x205
		/*@Error*/
	}
	GetCurrentGatherer().SetCurrentVent(GathererVent);
	log(,, __NFUN_112__("SetGathererVent - GathererVent set to: ", string(GathererVent)));
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function FindGathererVent()
{
	local array<GathererVent> UsableVents;
	local GathererVent VentIter;
	local float IterPathDistance;
	local PathNode IterVentFrontPathNode;
	local int i, j, LastUsedVentIndex;
	local SpawnZoneInfo SpawnZoneIter;
	local ShockAIScout GameScout;
	local float FindStartTime;

	FindStartTime = AppSeconds();
	GameScout = SpawningManager(Level().SpawningManager).GetGameScout();
	assert(__NFUN_119__(GameScout, none));
	LastUsedVentIndex = -1;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2F8
	/*@Error*/
	SpawnZoneIter = SpawningManager(Level().SpawningManager).GetSpawnZoneByName(Protector(m_Pawn).StartSpawnZones[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2EA
	/*@Error*/
	j = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2EA
	/*@Error*/
	VentIter = SpawnZoneIter.GathererVents[j];
	// End:0x2DC
	if(__NFUN_130__(__NFUN_130__(__NFUN_119__(VentIter, none), __NFUN_129__(VentIter.bProtectorsShouldntUse)), __NFUN_129__(VentIter.HasCurrentAI(ShockAI()))))
	{
		// End:0x200
		if(__NFUN_114__(VentIter, LastUsedGathererVent))
		{
			// End:0x1EC
			if(__NFUN_151__(UsableVents.Length, 0))
			{
				goto J0x2DC;
				LastUsedVentIndex = UsableVents.Length;
				IterVentFrontPathNode = VentIter.GetFrontPathNode();
				// End:0x233
				if(__NFUN_114__(IterVentFrontPathNode, none))
				{
					goto J0x2DC;
					IterPathDistance = GameScout.GetPathfindingDistanceBetween(m_Pawn, m_Pawn.Location, IterVentFrontPathNode, IterVentFrontPathNode.Location, m_Pawn.Class);
					// End:0x2BE
					if(__NFUN_180__(IterPathDistance, -1.0000000))
					{
					}
					goto J0x2DC;
					UsableVents[UsableVents.Length] = VentIter;
				}
				__NFUN_163__(j);
				// [Loop Continue]
				goto J0x11E;
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x75;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x361
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x341
				/*@Error*/
			}
			UsableVents.Remove(LastUsedVentIndex, 1);
			GathererVent = UsableVents[__NFUN_167__(UsableVents.Length)];
			log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " took "), string(__NFUN_175__(AppSeconds(), FindStartTime))), " seconds to look for a usable gatherer vent: "), string(GathererVent)));
		}
		return;
		@NULL
	}
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldStopMovingToGathererVent()
{
	return m_Pawn.IsAnimationHandleValid(ReleaseGathererAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function bool IsReadyForGathererExit()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_119__(GathererVent, none), m_Pawn.ReachedLocation(ProtectorLocationForGathererExit)), Class'ShockAI.MoveToAction'.static.IsRotatedTo(Rotator(__NFUN_216__(GathererVent.Location, m_Pawn.Location)), m_Pawn.Rotation));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnStoppedMovingToVentForGathererExit()
{
	// End:0x3D
	if(m_Pawn.ReachedLocation(ProtectorLocationForGathererExit))
	{
		ShockAI().bShouldApplyDisplacement = false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function MoveToVentForGathererToExit()
{
	local Rotator RotationToVent;

	assert(__NFUN_119__(GathererVent, none));
	ProtectorLocationForGathererExit = GathererVent.GetProtectorExitLocation(Protector(m_Pawn));
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Moving to vent ("), string(GathererVent.Name)), ") to get a new Gatherer at location: "), string(ProtectorLocationForGathererExit)));
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, ProtectorLocationForGathererExit);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.goalName = "MoveToVentForGathererToExit";
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGathererVent;
	CurrentMoveToGoal.__GetDesiredEndRotationOverride__Delegate = GetRotationTowardGathererVent;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnStoppedMovingToVentForGathererExit;
	CurrentMoveToGoal.postGoal(self);
	waitForGoal_AI_Goal(CurrentMoveToGoal);
	// End:0x2EE
	if(__NFUN_129__(CurrentMoveToGoal.wasAchieved()))
	{
		log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Could not move to vent ("), string(GathererVent.Name)), ") at location: "), string(ProtectorLocationForGathererExit)), ", sleeping for a 5 seconds and then failing behavior."));
		__NFUN_256__(5.0000000);
		fail(1);
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3D1
		/*@Error*/
		m_Pawn.__NFUN_267__(ProtectorLocationForGathererExit);
		RotationToVent.Yaw = Rotator(__NFUN_216__(GathererVent.Location, m_Pawn.Location)).Yaw;
	}
	m_Pawn.__NFUN_299__(RotationToVent);
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("Finished moving - m_Pawn.Rotation: ", string(m_Pawn.Rotation)), " rotationtovent: "), string(Rotator(__NFUN_216__(GathererVent.Location, m_Pawn.Location)))));
	ShockAI().bShouldApplyDisplacement = true;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PrepareForGathererToExitFromVent()
{
	SetGathererVent();
	assert(__NFUN_119__(GathererVent, none));
	MoveToVentForGathererToExit();
	ProtectorCommanderAction(achievingGoal.parentAction).ResetAttackTargets();
	ShockAI().BecomePassive();
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("PrepareForGathererToExitFromVent - m_Pawn.Rotation: ", string(m_Pawn.Rotation)), " rotationtovent: "), string(Rotator(__NFUN_216__(GathererVent.Location, m_Pawn.Location)))));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x128
	/*@Error*/
	CallVent();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function CallVent()
{
	local name CallVentAnimation;

	CallVentAnimation = Protector(m_Pawn).GetInitialCallVentAnimationName();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A1
	/*@Error*/
	ShockAI().PlaySpeech('SummonedGatherer');
	VentRelatedAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, CallVentAnimation);
	m_Pawn.FinishAnimation(VentRelatedAnimationHandle);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A1
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A1
	/*@Error*/
	__NFUN_256__(RandRange(PauseWhileWaitingToDoSecondCallVentTime.Min, PauseWhileWaitingToDoSecondCallVentTime.Max));
	ShockAI().PlaySpeech('SummonedGathererAnnoyed');
	CallVentAnimation = Protector(m_Pawn).GetSecondaryCallVentAnimationName();
	VentRelatedAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, CallVentAnimation);
	m_Pawn.FinishAnimation(VentRelatedAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function StartPrepareVentAnimations()
{
	local name PrepareVentAnimation;

	PrepareVentAnimation = Protector(m_Pawn).GetBeginPrepareVentAnimationName();
	VentRelatedAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, PrepareVentAnimation, Class'Engine.Actor'.4);
	m_Pawn.FinishAnimation(VentRelatedAnimationHandle);
	PrepareVentAnimation = Protector(m_Pawn).GetLoopPrepareVentAnimationName();
	VentRelatedAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, PrepareVentAnimation, Class'Engine.Actor'.8);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function FinishPrepareVentAnimations()
{
	local name EndPrepareVentAnimation;

	EndPrepareVentAnimation = Protector(m_Pawn).GetEndPrepareVentAnimationName();
	VentRelatedAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, EndPrepareVentAnimation);
	m_Pawn.FinishAnimation(VentRelatedAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayGathererPreEnterAnimation()
{
	local name GathererPreEnterAnimation;

	log('AI', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " 2D Distance to vent socket is: "), string(__NFUN_228__(__NFUN_216__(GathererVent.GetProtectorEnterLocation(Protector(m_Pawn)), m_Pawn.Location)))));
	GathererPreEnterAnimation = Protector(m_Pawn).GetGathererPreEnterAnimationName();
	VentRelatedAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, GathererPreEnterAnimation);
	m_Pawn.FinishAnimation(VentRelatedAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function HelpGathererIntoVent()
{
	m_Pawn.FinishAnimation(HelpGathererEnterAnimationHandle);
	ShockAI().bDoNotTakeAnyDamage = false;
	m_Pawn.UnTriggerEffectEvent('BecameImmuneToFrozenState');
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	achievingGoal.changePriority(achievingGoal.default.Priority);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function OnStoppedMovingToVentForGathererEnter()
{
	// End:0x3D
	if(m_Pawn.ReachedLocation(ProtectorLocationForGathererEnter))
	{
		ShockAI().bShouldApplyDisplacement = false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function MoveToVentForGathererEnter()
{
	assert(__NFUN_119__(GathererVent, none));
	ProtectorLocationForGathererEnter = GathererVent.GetProtectorEnterLocation(Protector(m_Pawn));
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Moving to vent ("), string(GathererVent.Name)), ") to help "), string(GetCurrentGatherer().Name)), " enter vent at location: "), string(ProtectorLocationForGathererEnter)));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, ProtectorLocationForGathererEnter);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.goalName = "MoveToVentForGathererEnter";
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToVent;
	CurrentMoveToGoal.__GetDesiredEndRotationOverride__Delegate = GetRotationAwayFromGathererVent;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnStoppedMovingToVentForGathererEnter;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RemoveMovementGoalForGathererEnter()
{
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	ShockAI().bShouldApplyDisplacement = true;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function HandlePickedUpGatherer()
{
	// End:0xDF
	if(m_Pawn.IsAnimationHandleValid(ReleaseGathererAnimationHandle))
	{
		m_Pawn.FinishAnimation(ReleaseGathererAnimationHandle);
		ShockAI().bDoNotTakeAnyDamage = false;
		m_Pawn.UnTriggerEffectEvent('BecameImmuneToFrozenState');
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
		achievingGoal.changePriority(achievingGoal.default.Priority);
		goto J0x372;
		// End:0x184
		if(Protector(m_Pawn).IsGathererAttached())
		{
			// End:0x181
			if(__NFUN_129__(Protector(m_Pawn).IsSafeForGathererToJumpOff(GetCurrentGatherer())))
			{
			}
			// End:0x181
			if(CurrentMoveToGoal.IsMovementSatisfied())
			{
				CurrentMoveToGoal.SetMovementType(1, m_Pawn.Controller.__NFUN_525__());
				goto J0x372;
				// End:0x23A
				if(__NFUN_154__(achievingGoal.Priority, 100))
				{
					ShockAI().bDoNotTakeAnyDamage = false;
					m_Pawn.UnTriggerEffectEvent('BecameImmuneToFrozenState');
					ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
				}
			}
		}
		ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
		achievingGoal.changePriority(achievingGoal.default.Priority);
		// End:0x29A
		if(__NFUN_154__(int(CurrentGathererState), int(0)))
		{
			// End:0x297
			if(__NFUN_119__(CurrentMoveToGoal.GetDestinationActor(), GetCurrentGatherer()))
			{
				CurrentMoveToGoal.SetMovementType(1, GetCurrentGatherer());
				goto J0x372;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x30B
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x308
				/*@Error*/
			}
			CurrentMoveToGoal.SetMovementType(1, GetCurrentGatherer());
			goto J0x372;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x372
			/*@Error*/
		}
	}
	CurrentMoveToGoal.SetMovementType(0, none, ProtectorLocationForGathererEnter);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PrepareForGathererToEnterVent()
{
	SetGathererVent();
	assert(__NFUN_119__(GathererVent, none));
	MoveToVentForGathererEnter();
	// End:0x74
	if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()), __NFUN_154__(int(CurrentGathererState), int(2))))
	{
		HandlePickedUpGatherer();
		yield();
		// [Loop Continue]
		goto J0x23;
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
	}
	@NULL
}

function SpawnGatherer()
{
	local Gatherer SpawnedGatherer;

	assert(__NFUN_119__(GathererVent, none));
	SpawnedGatherer = GathererVent.SpawnGatherer(Protector(m_Pawn));
	Protector(m_Pawn).SetCurrentGatherer(SpawnedGatherer);
	Protector(m_Pawn).ClearNextGathererLabel();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x28F
	/*@Error*/
	achievingGoal.changePriority(100);
	ShockAI().bDoNotTakeAnyDamage = true;
	m_Pawn.TriggerEffectEvent('BecameImmuneToFrozenState');
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
	// End:0x18C
	if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()), __NFUN_129__(m_Pawn.IsAnimationHandleValid(HelpGathererExitAnimationHandle))))
	{
		yield();
		// [Loop Continue]
		goto J0x134;
		// End:0x1D3
		if(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()))
		{
			m_Pawn.FinishAnimation(HelpGathererExitAnimationHandle);
			goto J0x1F3;
			m_Pawn.SmartPerTrackEaseOutAnimation(HelpGathererExitAnimationHandle);
			ShockAI().bDoNotTakeAnyDamage = false;
		}
		m_Pawn.UnTriggerEffectEvent('BecameImmuneToFrozenState');
		ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
		ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	}
	achievingGoal.changePriority(achievingGoal.default.Priority);
	goto J0x311;
	log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " Couldn't get "), string(GathererVent.Name)), " to spawn a gatherer, failing!"));
	instantFail(1);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool GetRotationTowardGathererVent(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(GathererVent.Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRotationAwayFromGathererVent(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(m_Pawn.Location, GathererVent.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldStopMovingToGatherer()
{
	local float DistanceToGatherer;

	// End:0x5A
	if(Protector(m_Pawn).IsGathererAttached())
	{
		// End:0x55
		if(Protector(m_Pawn).IsSafeForGathererToJumpOff(GetCurrentGatherer()))
		{
			return true;
			goto J0x57;
			return false;
			goto J0x77;
			// End:0x77
			if(GetCurrentGatherer().IsGettingOffProtector())
			{
			}
		}
		return true;
		DistanceToGatherer = __NFUN_175__(__NFUN_175__(__NFUN_228__(__NFUN_216__(GetCurrentGatherer().Location, m_Pawn.Location)), m_Pawn.CollisionRadius), GetCurrentGatherer().CollisionRadius);
	}
	// End:0x120
	if(bOutsideWaitDistance)
	{
		// End:0x11D
		if(__NFUN_176__(DistanceToGatherer, MinDistanceToGatherer))
		{
			bOutsideWaitDistance = false;
			NotifyGathererCaughtUp();
			goto J0x14D;
			// End:0x14D
			if(__NFUN_177__(DistanceToGatherer, DistanceForGathererToWait))
			{
				bOutsideWaitDistance = true;
				NotifyGathererTooFarAway();
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x261
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x21D
				/*@Error*/
			}
			// End:0x1F6
			if(__NFUN_154__(int(CurrentGathererState), int(1)))
			{
			}
			else
			{
				ShockAI().AddLocomotionKeyword('WaitingForGatherer', Class'ShockAI.ShockAI'.-1);
			}/* !MISMATCHING REMOVE, tried If got Type:Else Position:0x120! */
			return __NFUN_130__(__NFUN_178__(DistanceToGatherer, MinDistanceToGatherer), m_Pawn.LineOfSightTo(GetCurrentGatherer()));
			goto J0x21A;
			ShockAI().AddLocomotionKeyword('WaitingForGatherer', 1);
			return true;
			goto J0x25E;
			ShockAI().AddLocomotionKeyword('WaitingForGatherer', Class'ShockAI.ShockAI'.-1);
			bInsideMinDistance = false;
			return false;
			goto J0x284;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x284
			/*@Error*/
		}/* !MISMATCHING REMOVE, tried Else got Type:If Position:0x0C0! */
	}
	bInsideMinDistance = true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnStoppedMovingToGatherer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x23
	/*@Error*/
	bOutsideWaitDistance = false;
	NotifyGathererCaughtUp();
	return;
	@NULL
	CommanderAction
}

function bool ShouldStopMovingToVent()
{
	local float DistanceToGatherer;

	DistanceToGatherer = __NFUN_175__(__NFUN_175__(__NFUN_228__(__NFUN_216__(GetCurrentGatherer().Location, m_Pawn.Location)), m_Pawn.CollisionRadius), GetCurrentGatherer().CollisionRadius);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFB
	/*@Error*/
	// End:0xD4
	if(__NFUN_178__(DistanceToGatherer, MinDistanceToGatherer))
	{
		ShockAI().AddLocomotionKeyword('WaitingForGatherer', Class'ShockAI.ShockAI'.-1);
		bOutsideWaitDistance = false;
		return false;
		goto J0xF8;
		ShockAI().AddLocomotionKeyword('WaitingForGatherer', 1);
		return true;
		goto J0x11E;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11E
		/*@Error*/
	}
	bOutsideWaitDistance = true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetDesiredRotationWithGatherer(out Rotator DesiredRotation)
{
	// End:0x7A
	if(Protector(m_Pawn).IsGathererAttached())
	{
		// End:0x75
		if(Protector(m_Pawn).IsSafeForGathererToJumpOff(GetCurrentGatherer()))
		{
			DesiredRotation = m_Pawn.Rotation;
			return true;
			goto J0x77;
			return false;
			goto J0xB7;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xB7
			/*@Error*/
		}
		DesiredRotation = m_Pawn.Rotation;
	}
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function FollowGatherer()
{
	assert(__NFUN_119__(GetCurrentGatherer(), none));
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, GetCurrentGatherer());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.goalName = "FollowGatherer";
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGatherer;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetDesiredRotationWithGatherer;
	CurrentMoveToGoal.__OnMoveEnded__Delegate = OnStoppedMovingToGatherer;
	CurrentMoveToGoal.SetShouldNeverSucceed(__NFUN_155__(int(CurrentGathererState), int(1)));
	CurrentMoveToGoal.postGoal(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1FC
	/*@Error*/
	HandlePickedUpGatherer();
	yield();
	// [Loop Continue]
	goto J0x18D;
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	ShockAI().SetShouldWalk();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool GetFaceDirection(out Rotator DesiredRotation)
{
	// End:0x7A
	if(Protector(m_Pawn).IsGathererAttached())
	{
		// End:0x75
		if(Protector(m_Pawn).IsSafeForGathererToJumpOff(GetCurrentGatherer()))
		{
			DesiredRotation = m_Pawn.Rotation;
			return true;
			goto J0x77;
			return false;
			goto J0xCF;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xBA
			/*@Error*/
		}
		DesiredRotation = m_Pawn.Rotation;
	}
	return true;
	goto J0xCF;
	DesiredRotation = CurrentFaceDirection;
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function RotateToCurrentFaceDirection()
{
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.goalName = "RotateToCurrentFaceDirection";
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetFaceDirection;
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

function StartGuardRotationBehavior()
{
	// End:0x19
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		StopGuardRotationBehavior();
		AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	}
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, GetCurrentGatherer());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.goalName = "StartGuardRotationBehavior";
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetFaceDirection;
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGatherer;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function StopGuardRotationBehavior()
{
	// End:0x41
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.unPostGoal(self);
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		return;
		@NULL
		CommanderAction
		EcologyFighterCommanderAction
	}
	@NULL
}

function ShockPawn FindClosestTarget()
{
	local int i;
	local ShockPawn ClosestTarget, IterTarget;
	local ShockAI IterAI;
	local float ClosestTargetDistance, IterDistance;
	local array<ShockPawn> CurrentlyVisiblePawns;
	local bool bClosestIsAttacking, bIterIsAttacking;

	assert(achievingGoal.parentAction.__NFUN_303__('ProtectorCommanderAction'));
	ProtectorCommanderAction(achievingGoal.parentAction).GetCurrentlyVisiblePawns(CurrentlyVisiblePawns);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x245
	/*@Error*/
	IterTarget = CurrentlyVisiblePawns[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x237
	/*@Error*/
	IterDistance = __NFUN_225__(__NFUN_216__(IterTarget.Location, m_Pawn.Location));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x237
	/*@Error*/
	IterAI = ShockAI(IterTarget);
	// End:0x1A8
	if(__NFUN_132__(__NFUN_130__(__NFUN_119__(IterAI, none), IterAI.IsAttacking()), IterTarget.__NFUN_303__('ShockPlayer')))
	{
		bIterIsAttacking = true;
		goto J0x1B4;
		bIterIsAttacking = false;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x237
		/*@Error*/
		ClosestTarget = IterTarget;
		ClosestTargetDistance = IterDistance;
		bClosestIsAttacking = bIterIsAttacking;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x6A;
		return ClosestTarget;
		return;
	}
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function FindTargetToLookAtWhileGuarding()
{
	local ShockPawn LastThreatenTarget;

	LastThreatenTarget = Protector(m_Pawn).GetLastThreatenTarget();
	// End:0x89
	if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(LastThreatenTarget), m_Pawn.LineOfSightTo(LastThreatenTarget, true)))
	{
		CurrentGuardTarget = LastThreatenTarget;
		goto J0x9D;
		CurrentGuardTarget = FindClosestTarget();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x19B
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x198
		/*@Error*/
	}
	// End:0x15A
	if(__NFUN_129__(ShockAI().IsWeaponTargetWithinTrackingArea(CurrentGuardTarget)))
	{
		// End:0x120
		if(ShockAI().IsAimingWeapon())
		{
			ShockAI().StopAimingWeapon();
			CurrentFaceDirection = Rotator(__NFUN_216__(CurrentGuardTarget.Location, m_Pawn.Location));
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x198
			/*@Error*/
		}
		ShockAI().AimWeaponAtTarget(CurrentGuardTarget);
		goto J0x1CE;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1CE
		/*@Error*/
	}
	ShockAI().StopAimingWeapon();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function TransitionIntoAggressive()
{
	local name TransitionIntoAggressiveAnimName;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x118
	/*@Error*/
	TransitionIntoAggressiveAnimName = Protector(m_Pawn).GetTransitionIntoAggressiveName();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x118
	/*@Error*/
	TransitionIntoStateAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, TransitionIntoAggressiveAnimName);
	// End:0xE0
	if(__NFUN_130__(m_Pawn.IsAnimationHandleValid(TransitionIntoStateAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEntirelyEasedIn(TransitionIntoStateAnimationHandle))))
	{
		yield();
		// [Loop Continue]
		goto J0x89;
		ShockAI().BecomeAggressive();
		m_Pawn.FinishAnimation(TransitionIntoStateAnimationHandle);
		return;
		@NULL
		EcologyAI
	}
	CommanderAction
	@NULL
}

function TransitionIntoPassive()
{
	local name TransitionIntoPassiveAnimName;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x118
	/*@Error*/
	TransitionIntoPassiveAnimName = Protector(m_Pawn).GetTransitionIntoIdleName();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x118
	/*@Error*/
	TransitionIntoStateAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, TransitionIntoPassiveAnimName);
	// End:0xE0
	if(__NFUN_130__(m_Pawn.IsAnimationHandleValid(TransitionIntoStateAnimationHandle), __NFUN_129__(m_Pawn.IsAnimationPerTrackEntirelyEasedIn(TransitionIntoStateAnimationHandle))))
	{
		yield();
		// [Loop Continue]
		goto J0x89;
		ShockAI().BecomePassive();
		m_Pawn.FinishAnimation(TransitionIntoStateAnimationHandle);
		return;
		@NULL
		EcologyAI
	}
	CommanderAction
	@NULL
}

function GuardGatherer()
{
	local float TimeToRotate;

	assert(__NFUN_119__(GetCurrentGatherer(), none));
	ShockAI().AddLocomotionKeyword('Guarding', 1);
	TimeToRotate = __NFUN_174__(Level().TimeSeconds, RandRange(TimeRangeBeforeTurningAroundWhileGuarding.Min, TimeRangeBeforeTurningAroundWhileGuarding.Max));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x244
	/*@Error*/
	HandlePickedUpGatherer();
	// End:0x14C
	if(__NFUN_129__(ShockAI().IsAggressive()))
	{
		TransitionIntoAggressive();
		CurrentFaceDirection = m_Pawn.Rotation;
		// End:0x14C
		if(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()))
		{
			StartGuardRotationBehavior();
			// End:0x17A
			if(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()))
			{
				FindTargetToLookAtWhileGuarding();
				// End:0x237
				if(__NFUN_130__(__NFUN_114__(CurrentGuardTarget, none), __NFUN_179__(Level().TimeSeconds, TimeToRotate)))
				{
				}
			}
			CurrentFaceDirection = Rotator(__NFUN_211__(Vector(m_Pawn.Rotation)));
			TimeToRotate = __NFUN_174__(Level().TimeSeconds, RandRange(TimeRangeBeforeTurningAroundWhileGuarding.Min, TimeRangeBeforeTurningAroundWhileGuarding.Max));
		}
		yield();
		// [Loop Continue]
		goto J0x93;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x277
		/*@Error*/
		ShockAI().StopAimingWeapon();
		StopGuardRotationBehavior();
		ShockAI().AddLocomotionKeyword('Guarding', Class'ShockAI.ShockAI'.-1);
		TransitionIntoPassive();
		return;
		@NULL
	}
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldStopMovingToGathererBody()
{
	return __NFUN_178__(__NFUN_225__(__NFUN_216__(GetCurrentGatherer().Location, m_Pawn.Location)), DistanceToVisitGatherer);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRotationTowardGathererBody(out Rotator DesiredRotation)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x59
	/*@Error*/
	DesiredRotation = Rotator(__NFUN_216__(GetCurrentGatherer().Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToVisitGathererBody()
{
	assert(__NFUN_119__(GetCurrentGatherer(), none));
	assert(__NFUN_129__(GetCurrentGatherer().IsAlive()));
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, GetCurrentGatherer());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.goalName = "MoveToVisitGathererBody";
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToGathererBody;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationTowardGathererBody;
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

function VisitGathererBody()
{
	local name MournAnimationName;

	MournAnimationName = Protector(m_Pawn).GetMournGathererAnimationName();
	// End:0x8F
	if(__NFUN_255__(MournAnimationName, 'None'))
	{
		MournAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, MournAnimationName);
		m_Pawn.FinishAnimation(MournAnimationHandle);
		goto J0xFB;
		log('AI', 2, __NFUN_112__(__NFUN_112__("No mourn animation found for ", string(m_Pawn.Name)), " sleeping for 5 seconds"));
	}
	__NFUN_256__(5.0000000);
	GetCurrentGatherer().IncinerateGatherer();
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	ResetInternalState();
	TransitionIntoPassive();
	// End:0x2B
	if(bEscortingLinkedGatherer)
	{
		goto 'FollowGatherer';
		PrepareForGathererToExitFromVent();
	}
	// End:0xD1
	if(__NFUN_132__(__NFUN_132__(GathererVent.bDontSpawnGatherers, ShockAI().IsBerserk()), __NFUN_129__(SpawningManager(Level().SpawningManager).CanSpawnNewGatherer())))
	{
		StartPrepareVentAnimations();
		__NFUN_256__(GathererVent.WaitForNoGathererTime);
		FinishPrepareVentAnimations();
		goto J0x3ED;
		// End:0x1B6
		if(__NFUN_129__(IsReadyForGathererExit()))
		{
			log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__("! IsReadyForGathererExit - m_Pawn.Rotation: ", string(m_Pawn.Rotation)), " rotationtovent: "), string(Rotator(__NFUN_216__(GathererVent.Location, m_Pawn.Location)))));
		}
		GathererVent.ResetCurrentAI(ShockAI());
		yield();
		goto 'MoveToPrepareVent';
		SpawnGatherer();
		GathererVent.ResetCurrentAI(ShockAI());
		// End:0x211
		if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer())))
		{
		}
		goto 'VisitGathererBody';
		FollowGatherer();
		// End:0x24B
		if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer())))
		{
			goto 'VisitGathererBody';
			// End:0x299
			if(__NFUN_155__(int(CurrentGathererState), int(2)))
			{
				GuardGatherer();
			}
			// End:0x299
			if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer())))
			{
				goto 'VisitGathererBody';
				// End:0x2CD
				if(__NFUN_132__(__NFUN_154__(int(CurrentGathererState), int(0)), __NFUN_154__(int(CurrentGathererState), int(1))))
				{
				}
				goto 'FollowGatherer';
				PrepareForGathererToEnterVent();
				// End:0x307
				if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer())))
				{
					goto 'VisitGathererBody';
				}
			}
			// End:0x34B
			if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()), __NFUN_154__(int(CurrentGathererState), int(3))))
			{
			}
			PlayGathererPreEnterAnimation();
			// End:0x392
			if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()), __NFUN_154__(int(CurrentGathererState), int(3))))
			{
				yield();
			}
			goto J0x34B;
			RemoveMovementGoalForGathererEnter();
			// End:0x3E3
			if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()), __NFUN_154__(int(CurrentGathererState), int(4))))
			{
				HelpGathererIntoVent();
			}
			goto J0x3ED;
			FinishPrepareVentAnimations();
			yield();
			goto 'Begin';
			// End:0x442
			if(__NFUN_132__(__NFUN_114__(GetCurrentGatherer(), none), GetCurrentGatherer().bDeleteMe))
			{
			}
			yield();
			goto 'Begin';
			TransitionIntoPassive();
			MoveToVisitGathererBody();
			VisitGathererBody();
			bMournedGatherer = true;
			yield();
			goto 'Begin';
		}
		stop;
		J0x3ED:
						
		@NULL
		@NULL
		@NULL
		@NULL
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		/*@Error*/;
		// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.get_CurrentToken() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 40
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 845
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
		// 1 & Type:If Position:0x442
	}
}

defaultproperties
{
	InitialCallVentSuccessChance=0.7500000
	TimeRangeBeforeTurningAroundWhileGuarding=(Min=11.0000000,Max=11.0000000)
	PauseWhileWaitingToDoSecondCallVentTime=(Min=2.0000000,Max=4.0000000)
	DistanceForGathererToWait=400.0000000
	MinDistanceToGatherer=80.0000000
	MaxDistanceToGatherer=300.0000000
	PauseWhileVisitingDeadGathererTime=(Min=3.0000000,Max=5.0000000)
	MaxDistanceToLookAtNearbyVisibleTargetsWhileGuarding=2500.0000000
	DistanceToVisitGatherer=100.0000000
	satisfiesGoal=Class'ShockAI.EscortGoal'
	bExclusiveAction=true
}