class ReturnToVentAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) bool bReturningWithProtector;
var(Parameters) bool bRunWithoutProtector;
var private MoveToGoal CurrentMoveToGoal;
var private int GenericAnimationHandle;
var private bool bEnterWithProtectorSuccessful;
var private bool bInsideMinDistance;
var private bool bOutsideRunDistance;
var private bool bFollowingProtector;
var private bool bBecameTired;
var private Vector GathererEnterLocation;
var config array<name> EnterWithRosieAnimations;
var config array<name> EnterWithBouncerAnimations;
var config array<name> EnterWithSPFAnimations;
var config array<name> EnterWithoutProtectorAnimations;
var config array<name> PreEnterWithProtectorAnimations;
var config array<name> MournAnimations;
var private config float DistanceXYToMourn;
var private config float DistanceToProtectorToRun;
var private config float MinDistanceToProtector;
var private config float MaxDistanceToProtector;
var private config float TimeBeforeStartingTiredMovement;
var private config Range TimeBeforeStartingTiredBehaviorRange;
var config array<name> ThankSavingPlayerAnimations;
var private config float DistanceToStopForOtherAIsBeforeEnteringVent;
var private config float DistanceToClaimVent;

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
		if(m_Pawn.IsAnimationHandleValid(GenericAnimationHandle))
		{
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(GenericAnimationHandle);
		Gatherer(m_Pawn).GetCurrentVent().ResetCurrentAI(ShockAI());
	}
	ShockAI().StopSpeech('HeadedToVent');
	ShockAI().AddLocomotionKeyword('ReturnToVent', Class'ShockAI.ShockAI'.-1);
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	ShockAI().StopSpeech('HeadedToVent');
	ShockAI().AddLocomotionKeyword('ReturnToVent', Class'ShockAI.ShockAI'.-1);
	return;
	@NULL
	CommanderAction
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	// End:0x9B
	if(__NFUN_130__(__NFUN_129__(bEnterWithProtectorSuccessful), __NFUN_132__(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort())), __NFUN_129__(bReturningWithProtector))))
	{
		ShockAI().BecomeAggressive();
		ShockAI().SetShouldRun();
		goto J0x127;
		ShockAI().BecomePassive();
		ShockAI().SetShouldWalk();
	}
	ShockAI().PlaySpeech('HeadedToVent');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x127
	/*@Error*/
	bInsideMinDistance = false;
	ShockAI().AddLocomotionKeyword('ReturnToVent', 1);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldStopMovingToProtector()
{
	local float DistanceToGatherer;
	local Protector ProtectorEscort;

	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	// End:0x51
	if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort)))
	{
		return true;
		DistanceToGatherer = __NFUN_175__(__NFUN_175__(__NFUN_228__(__NFUN_216__(ProtectorEscort.Location, m_Pawn.Location)), m_Pawn.CollisionRadius), ProtectorEscort.CollisionRadius);
	}
	// End:0xEE
	if(bOutsideRunDistance)
	{
		// End:0xEB
		if(__NFUN_176__(DistanceToGatherer, MaxDistanceToProtector))
		{
			bOutsideRunDistance = false;
			goto J0x111;
			// End:0x111
			if(__NFUN_177__(DistanceToGatherer, DistanceToProtectorToRun))
			{
				bOutsideRunDistance = true;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x14B
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x13A
				/*@Error*/
				return true;
				goto J0x148;
				bInsideMinDistance = false;
				return false;
				goto J0x175;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x173
				/*@Error*/
			}
		}
		bInsideMinDistance = true;
		return true;
		goto J0x175;
		return false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function BecomeTired()
{
	bBecameTired = true;
	ShockAI().AddLocomotionKeyword('ReturnToVent', Class'ShockAI.ShockAI'.-1);
	ShockAI().AddLocomotionKeyword('Tired', 1);
	__NFUN_256__(RandRange(TimeBeforeStartingTiredBehaviorRange.Min, TimeBeforeStartingTiredBehaviorRange.Max));
	// End:0xFF
	if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
	{
		Gatherer(m_Pawn).BecomeTired();
		goto J0x132;
		ShockAI().AddLocomotionKeyword('Tired', Class'ShockAI.ShockAI'.-1);
		return;
		@NULL
		EcologyAI
		EcologyFighterCommanderAction
	}
	@NULL
}

function FollowProtector()
{
	local float StartToAttemptTiredBehaviorTime;

	bFollowingProtector = true;
	StartToAttemptTiredBehaviorTime = __NFUN_174__(Level().TimeSeconds, TimeBeforeStartingTiredMovement);
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, Gatherer(m_Pawn).GetProtectorEscort());
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToProtector;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2A6
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x299
	/*@Error*/
	BecomeTired();
	yield();
	// [Loop Continue]
	goto J0x154;
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	bFollowingProtector = false;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool GetEndRotationTowardGathererVent(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(Gatherer(m_Pawn).GetCurrentVent().Location, GathererEnterLocation));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRotationWhileMovingToEnter(out Rotator DesiredRotation)
{
	// End:0x3F
	if(ShouldStopMovingTowardGathererVent())
	{
		DesiredRotation = Rotator(__NFUN_216__(GathererEnterLocation, m_Pawn.Location));
		return true;
		goto J0x41;
		return false;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function bool ShouldStopMovingTowardGathererVent()
{
	local GathererVent CurrentVent;
	local ShockAI CurrentAI;

	assert(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort())));
	CurrentVent = Gatherer(m_Pawn).GetCurrentVent();
	CurrentAI = CurrentVent.GetCurrentAI();
	// End:0xF4
	if(__NFUN_114__(CurrentAI, none))
	{
		// End:0xF1
		if(IsPointWithinCylinder(GathererEnterLocation, m_Pawn.Location, DistanceToClaimVent, 200.0000000))
		{
			CurrentVent.SetCurrentAI(ShockAI());
			goto J0x149;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x149
			/*@Error*/
			return true;
			return false;
			return;
		}
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToGathererEnterLocation(Vector EnterLocation)
{
	GathererEnterLocation = EnterLocation;
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, EnterLocation);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredEndRotationOverride__Delegate = GetEndRotationTowardGathererVent;
	// End:0x1C1
	if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort())))
	{
		CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationWhileMovingToEnter;
		CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingTowardGathererVent;
		CurrentMoveToGoal.SetShouldNeverSucceed(true);
		CurrentMoveToGoal.postGoal(self);
		// End:0x1BE
		if(__NFUN_129__(CurrentMoveToGoal.IsMovementSatisfied(true)))
		{
			yield();
			goto J0x194;
			goto J0x1EC;
			CurrentMoveToGoal.postGoal(self);
			waitForGoal_AI_Goal(CurrentMoveToGoal);
			CurrentMoveToGoal.unPostGoal(self);
			CurrentMoveToGoal.__NFUN_198__();
			CurrentMoveToGoal = none;
			log('AI', 4, __NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " 2D Distance to EnterDestination is: "), string(__NFUN_228__(__NFUN_216__(EnterLocation, m_Pawn.Location)))));
		}
	}
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool GetRotationToVent(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(Gatherer(m_Pawn).GetCurrentVent().Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function PlayPreEnterWithProtectorAnimation()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x68
	/*@Error*/
	GenericAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, PreEnterWithProtectorAnimations[__NFUN_167__(PreEnterWithProtectorAnimations.Length)]);
	m_Pawn.FinishAnimation(GenericAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function name GetEnterWithProtectorAnimationName()
{
	local name EnterWithProtectorAnimationName;
	local Protector ProtectorEscort;

	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	assert(__NFUN_119__(ProtectorEscort, none));
	// End:0x78
	if(ProtectorEscort.__NFUN_303__('Rosie'))
	{
		EnterWithProtectorAnimationName = EnterWithRosieAnimations[__NFUN_167__(EnterWithRosieAnimations.Length)];
		goto J0xF3;
		// End:0xB7
		if(ProtectorEscort.__NFUN_303__('Bouncer'))
		{
			EnterWithProtectorAnimationName = EnterWithBouncerAnimations[__NFUN_167__(EnterWithBouncerAnimations.Length)];
		}
		goto J0xF3;
		assert(ProtectorEscort.__NFUN_303__('SPF'));
		EnterWithProtectorAnimationName = EnterWithSPFAnimations[__NFUN_167__(EnterWithSPFAnimations.Length)];
		return EnterWithProtectorAnimationName;
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function PlayEnterWithProtectorAnimation()
{
	local name EnterWithProtectorAnimationName;

	EnterWithProtectorAnimationName = GetEnterWithProtectorAnimationName();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x91
	/*@Error*/
	GenericAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, EnterWithProtectorAnimationName, Class'Engine.Actor'.4);
	m_Pawn.FinishAnimation(GenericAnimationHandle);
	bEnterWithProtectorSuccessful = true;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayEnterWithoutProtectorAnimation()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x77
	/*@Error*/
	GenericAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, EnterWithoutProtectorAnimations[__NFUN_167__(EnterWithoutProtectorAnimations.Length)], Class'Engine.Actor'.4);
	m_Pawn.FinishAnimation(GenericAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool ShouldStopMovingToMourn()
{
	local Protector ProtectorEscort;

	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	return IsPointWithinCylinder(ProtectorEscort.Location, m_Pawn.Location, DistanceXYToMourn, __NFUN_171__(m_Pawn.CollisionHeight, 2.0000000));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetMoveToMournRotationOverride(out Rotator DesiredRotation)
{
	local Protector ProtectorEscort;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x82
	/*@Error*/
	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	DesiredRotation = Rotator(__NFUN_216__(ProtectorEscort.Location, m_Pawn.Location));
	return true;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function MoveToMournProtector()
{
	local Protector ProtectorEscort;

	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	assert(Class'Engine.Pawn'.static.checkAlive(ProtectorEscort));
	AssertWithDescription(__NFUN_114__(CurrentMoveToGoal, none), __NFUN_112__(string(Name), " expected CurrentMoveToGoal to be None!"));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, ProtectorEscort);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__ShouldStopMoving__Delegate = ShouldStopMovingToMourn;
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetMoveToMournRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RemoveMournProtectorMoveBehavior()
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

function PlayMournProtectorAnimation()
{
	local name MournAnimation;

	MournAnimation = MournAnimations[__NFUN_167__(MournAnimations.Length)];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	GenericAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, MournAnimation);
	m_Pawn.FinishAnimation(GenericAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function FacePlayerInstantly()
{
	local Rotator DesiredRotation;

	DesiredRotation.Yaw = Rotator(__NFUN_216__(Level().GetLocalPlayerController().Pawn.Location, m_Pawn.Location)).Yaw;
	m_Pawn.__NFUN_299__(DesiredRotation);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function PlayThankYouAnimation()
{
	local name ThankSavingPlayerAnimation;

	ThankSavingPlayerAnimation = ThankSavingPlayerAnimations[__NFUN_167__(ThankSavingPlayerAnimations.Length)];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	GenericAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ThankSavingPlayerAnimation);
	m_Pawn.FinishAnimation(GenericAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool IsReadyToEnterVent(GathererVent GathererVent, Vector GathererEnterLocation)
{
	return __NFUN_130__(m_Pawn.ReachedLocation(GathererEnterLocation), Class'ShockAI.MoveToAction'.static.IsRotatedTo(Rotator(__NFUN_216__(GathererVent.Location, GathererEnterLocation)), m_Pawn.Rotation));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsReadyToEnterVentAlone()
{
	local GathererVent GathererVent;
	local Vector GathererEnterLocation;
	local ShockAI CurrentAIUsingVent;

	GathererVent = Gatherer(m_Pawn).GetCurrentVent();
	AssertWithDescription(__NFUN_119__(GathererVent, none), __NFUN_112__(__NFUN_112__("IsReadyToEnterVentAlone - ", string(m_Pawn.Name)), " has no GathererVent!"));
	GathererEnterLocation = GathererVent.GetGathererEnterWithoutProtectorLocation();
	CurrentAIUsingVent = GathererVent.GetCurrentAI();
	return __NFUN_130__(__NFUN_132__(__NFUN_114__(CurrentAIUsingVent, none), __NFUN_114__(CurrentAIUsingVent, m_Pawn)), IsReadyToEnterVent(GathererVent, GathererEnterLocation));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsReadyToEnterVentWithProtector()
{
	local GathererVent GathererVent;
	local Vector GathererEnterLocation;
	local Protector ProtectorEscort;

	GathererVent = Gatherer(m_Pawn).GetCurrentVent();
	AssertWithDescription(__NFUN_119__(GathererVent, none), __NFUN_112__(__NFUN_112__("IsReadyToEnterVentWithProtector - ", string(m_Pawn.Name)), " has no GathererVent!"));
	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	GathererEnterLocation = GathererVent.GetGathererEnterWithProtectorLocation(ProtectorEscort);
	return IsReadyToEnterVent(GathererVent, GathererEnterLocation);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{	J0x00:
	// End:0x27 [Loop If]
	if(m_Pawn.bHidden)
	{
		yield();
		// [Loop Continue]
		goto J0x00;
		useResources(Class'VengeanceShared.AI_Resource'.2);
	}
	// End:0x59C
	if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()), bReturningWithProtector))
	{
		ShockAI().BecomePassive();
		ShockAI().SetShouldWalk();
		ShockAI().PlaySpeech('HeadedToVent');
		ShockAI().AddLocomotionKeyword('ReturnToVent', 1);
		FollowProtector();
		Gatherer(m_Pawn).DeactivateAlertSensor();
		// End:0x59C
		if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
		{
			ShockAI().bAvoidFuturePawnCollisions = false;
			ShockAI().AddLocomotionKeyword('ReturnToVent', 1);
			MoveToGathererEnterLocation(Gatherer(m_Pawn).GetCurrentVent().GetGathererEnterWithProtectorLocation(Gatherer(m_Pawn).GetProtectorEscort()));
			ShockAI().AddLocomotionKeyword('ReturnToVent', Class'ShockAI.ShockAI'.-1);
			// End:0x59C
			if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
			{
				// End:0x284
				if(__NFUN_129__(IsReadyToEnterVentWithProtector()))
				{
					yield();
					goto 'MoveToEnterWithProtector';
					// End:0x374
					if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()), __NFUN_129__(Class'ShockAI.MoveToAction'.static.IsRotatedTo(Gatherer(m_Pawn).GetProtectorEscort().Rotation, Rotator(__NFUN_216__(Gatherer(m_Pawn).GetProtectorEscort().Location, Gatherer(m_Pawn).GetCurrentVent().Location))))))
					{
					}
					yield();
					// [Loop Continue]
					goto J0x284;
					// End:0x59C
					if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
					{
						Gatherer(m_Pawn).GetProtectorEscort().NotifyGathererPlayingPreEnterAnimation();
						ShockAI().StopSpeech('HeadedToVent');
						ShockAI().PlaySpeech('ThankedProtector');
						PlayPreEnterWithProtectorAnimation();
					}
					// End:0x59C
					if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
					{
						// End:0x485
						if(__NFUN_129__(IsReadyToEnterVentWithProtector()))
						{
							yield();
							goto 'MoveToEnterWithProtector';
							// End:0x59C
							if(Class'Engine.Pawn'.static.checkAlive(Gatherer(m_Pawn).GetProtectorEscort()))
							{
								Gatherer(m_Pawn).GetProtectorEscort().NotifyGathererReadyToEnterVent();
								Gatherer(m_Pawn).BecomeNonPhysical();
								achievingGoal.changePriority(100);
								ShockAI().bDoNotTakeAnyDamage = true;
								m_Pawn.TriggerEffectEvent('BecameImmuneToFrozenState');
								ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
							}
							ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
							PlayEnterWithProtectorAnimation();
							/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
								
							*/

							// End:0x845
							/*@Error*/
							// End:0x652
							if(Gatherer(m_Pawn).IsSaved())
							{
								FacePlayerInstantly();
								PlayThankYouAnimation();
								ShockAI().PlaySpeech('GathererFreed');
								ShockAI().StopSpeech('HeadedToVent');
								// End:0x6B0
								if(bRunWithoutProtector)
								{
									ShockAI().BecomePassive();
									ShockAI().SetShouldRun();
								}
							}
						}
					}
				}
			}
			// End:0x704
			if(__NFUN_129__(IsReadyToEnterVentAlone()))
			{
				MoveToGathererEnterLocation(Gatherer(m_Pawn).GetCurrentVent().GetGathererEnterWithoutProtectorLocation());
				yield();
				goto J0x6B0;
				Gatherer(m_Pawn).GetCurrentVent().SetCurrentAI(ShockAI());
				ShockAI().StopSpeech('GathererFreed', true);
				Gatherer(m_Pawn).BecomeNonPhysical();
			}
			achievingGoal.changePriority(100);
			ShockAI().bDoNotTakeAnyDamage = true;
			m_Pawn.TriggerEffectEvent('BecameImmuneToFrozenState');
			ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
		}
		ShockAI().NotifyFallDownHitReactionPreventionDesired(self);
		PlayEnterWithoutProtectorAnimation();
		Gatherer(m_Pawn).GetCurrentVent().ResetCurrentAI(ShockAI());
	}
	ShockAI().dispatchMessage(Class'ShockAI.MessageGathererEnteredVent'.static.Allocate(self)., construct_Gatherer(Gatherer(m_Pawn)));
	m_Pawn.SetHidden(true);
	m_Pawn.LifeSpan = 0.0100000;
	stop;	
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/;
}

defaultproperties
{
	EnterWithRosieAnimations[0]="GA_EnterVentProtectorRosie"
	EnterWithBouncerAnimations[0]="GA_EnterVentProtectorBouncer"
	EnterWithSPFAnimations[0]="GA_EnterVentProtectorSPF"
	EnterWithoutProtectorAnimations[0]="GA_EnterVentAlone"
	MournAnimations[0]="GA_InterestFloor_A"
	DistanceXYToMourn=100.0000000
	MinDistanceToProtector=50.0000000
	MaxDistanceToProtector=200.0000000
	TimeBeforeStartingTiredMovement=5.0000000
	TimeBeforeStartingTiredBehaviorRange=(Min=2.0000000,Max=4.0000000)
	ThankSavingPlayerAnimations[0]="GA_SaveThankYou"
	ThankSavingPlayerAnimations[1]="GA_SaveThankYou_B"
	ThankSavingPlayerAnimations[2]="GA_SaveThankYou_C"
	DistanceToStopForOtherAIsBeforeEnteringVent=500.0000000
	DistanceToClaimVent=700.0000000
	satisfiesGoal=Class'ShockAI.ReturnToVentGoal'
	bExclusiveAction=true
}