class PickedUpPanicAction extends BasePanicAction implements IInterestedPawnDied
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn AttackPawn;
var(Parameters) private Vector PointToBePickedUpAt;
var private MoveToGoal CurrentMoveToGoal;
var private int PanicAnimHandle;
var private config float ChanceToHaveGathererPickedUpAIAttacker;
var private config float ChanceToHaveGathererPickedUpPlayerAttacker;
var private config float MaxDistanceToProtector;
var private config float MinProtectorHealthPercentage;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	assert(__NFUN_119__(m_Pawn, none));
	m_Pawn.Level.RegisterNotifyPawnDied(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
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
		ShockAI().StopSpeech('Panicked');
	}
	// End:0x130
	if(Class'Engine.Pawn'.static.checkAlive(m_Pawn))
	{
		// End:0xBA
		if(m_Pawn.IsAnimationHandleValid(PanicAnimHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(PanicAnimHandle);
			Gatherer(m_Pawn).SetIsJumpingOnProtector(false);
			// End:0x130
			if(__NFUN_130__(__NFUN_119__(ProtectorEscort, none), ProtectorEscort.IsGathererAttached()))
			{
			}
			DetachGathererFromProtector();
			Gatherer(m_Pawn).BecomePhysical();
			DisallowAttachedKeywords();
			Gatherer(m_Pawn).NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
			Gatherer(m_Pawn).NotifyFallDownHitReactionPreventionNoLongerDesired(self);
			m_Pawn.Level.UnRegisterNotifyPawnDied(self);
		}
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DisallowAttachedKeywords()
{
	ShockAI().AddLocomotionKeyword('AttachedToBouncer', Class'ShockAI.ShockAI'.-1);
	ShockAI().AddLocomotionKeyword('AttachedToSPF', Class'ShockAI.ShockAI'.-1);
	return;
	@NULL
	CommanderAction
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	// End:0x41
	if(__NFUN_114__(DeadPawn, m_Pawn))
	{
		DetachGathererFromProtector();
		Gatherer(m_Pawn).BecomePhysical();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function float selectionHeuristic(AI_Goal Goal)
{
	local VPawn Pawn;
	local Gatherer GathererPawn;
	local Protector LocalProtectorEscort;
	local float ChanceToHaveGathererPickedUp, DistanceToPickUpGatherer;
	local Vector PickUpPoint;

	Pawn = Goal.resource.Pawn();
	assert(__NFUN_119__(Pawn, none));
	GathererPawn = Gatherer(Pawn);
	assert(__NFUN_119__(GathererPawn, none));
	LocalProtectorEscort = GathererPawn.GetProtectorEscort();
	assert(__NFUN_132__(__NFUN_119__(LocalProtectorEscort, none), __NFUN_119__(GathererPawn.GetPlayerEscort(), none)));
	// End:0xCC
	if(__NFUN_114__(LocalProtectorEscort, none))
	{
		return 0.0000000;
		// End:0x10D
		if(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(PanicGoal(Goal).AttackPawn)))
		{
			return 0.0000000;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x407
			/*@Error*/
		}
		DistanceToPickUpGatherer = LocalProtectorEscort.GetDistanceToPickUpGatherer();
	}
	// End:0x1B0
	if(PanicGoal(Goal).AttackPawn.__NFUN_303__('ShockPlayer'))
	{
		ChanceToHaveGathererPickedUp = default.ChanceToHaveGathererPickedUpPlayerAttacker;
		goto J0x1C3;
		ChanceToHaveGathererPickedUp = default.ChanceToHaveGathererPickedUpAIAttacker;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x407
		/*@Error*/
	}
	LocalProtectorEscort.SetShouldPickUpGatherer(true, PickUpPoint);
	PanicGoal(Goal).PointToBePickedUpAt = PickUpPoint;
	return 1.0000000;
	LocalProtectorEscort.SetShouldPickUpGatherer(false);
	return 0.0000000;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
	@NULL
}

function NotifyPlayPickedUpAnimation()
{
	local name PickedUpAnimation;

	Gatherer(m_Pawn).NotifyFullBodyHitReactionPreventionDesired(self);
	Gatherer(m_Pawn).NotifyFallDownHitReactionPreventionDesired(self);
	Gatherer(m_Pawn).SetIsJumpingOnProtector(true);
	Gatherer(m_Pawn).BecomeNonPhysical();
	PickedUpAnimation = ProtectorEscort.GetGathererPickedUpAnimation();
	assert(__NFUN_255__(PickedUpAnimation, 'None'));
	PanicAnimHandle = m_Pawn.PlayAnimationOnChannel(0, PickedUpAnimation, Class'Engine.Actor'.4);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRotationTowardProtectorEscort(out Rotator DesiredRotation)
{
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	DesiredRotation = Rotator(__NFUN_216__(ProtectorEscort.Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsProtectorEscortedRotatedCorrectly()
{
	assert(__NFUN_119__(ProtectorEscort, none));
	return Class'ShockAI.MoveToAction'.static.IsRotatedTo(ProtectorEscort.Rotation, Rotator(__NFUN_216__(m_Pawn.Location, ProtectorEscort.Location)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function MoveToGetPickedUp()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	assert(__NFUN_119__(ProtectorEscort, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, PointToBePickedUpAt);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationTowardProtectorEscort;
	CurrentMoveToGoal.SetShouldModifyTravelThrottle(false);
	CurrentMoveToGoal.SetLocomotionResumeAlignmentThreshold(0.0000000);
	ShockAI().bAvoidFuturePawnCollisions = false;
	CurrentMoveToGoal.postGoal(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A3
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0x125;
	ShockAI().bAvoidFuturePawnCollisions = true;
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

// Export UPickedUpPanicAction::execAttachToProtectorEscort(FFrame&, void* const)
native function AttachToProtectorEscort();

function SetAttachedAnimationKeyword()
{
	assert(__NFUN_132__(ProtectorEscort.__NFUN_303__('Bouncer'), ProtectorEscort.__NFUN_303__('SPF')));
	// End:0x88
	if(ProtectorEscort.__NFUN_303__('Bouncer'))
	{
		ShockAI().AddLocomotionKeyword('AttachedToBouncer', Class'ShockAI.ShockAI'.0);
		goto J0xB7;
		ShockAI().AddLocomotionKeyword('AttachedToSPF', Class'ShockAI.ShockAI'.0);
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function JumpOnProtector()
{
	assert(m_Pawn.IsAnimationHandleValid(PanicAnimHandle));
	SetAttachedAnimationKeyword();
	m_Pawn.FinishAnimation(PanicAnimHandle);
	m_Pawn.InstantPerTrackEaseOutAnimation(PanicAnimHandle);
	AttachToProtectorEscort();
	Gatherer(m_Pawn).SetIsJumpingOnProtector(false);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool IsJumpOffPointUsable()
{
	return __NFUN_130__(__NFUN_119__(ProtectorEscort, none), ProtectorEscort.IsSafeForGathererToJumpOff(Gatherer(m_Pawn)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsAttachedToProtector()
{
	return __NFUN_130__(__NFUN_119__(ProtectorEscort, none), ProtectorEscort.IsGathererAttached());
	return;
	@NULL
	CommanderAction
}

function DetachGathererFromProtector()
{
	local Rotator GathererRotation;

	ProtectorEscort.DetachFromBone(m_Pawn);
	GathererRotation.Yaw = m_Pawn.Rotation.Yaw;
	GathererRotation.Pitch = 0;
	GathererRotation.Roll = 0;
	m_Pawn.__NFUN_299__(GathererRotation);
	m_Pawn.__NFUN_267__(m_Pawn.Location);
	m_Pawn.ForcePoseUpdate();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function PlayJumpOffAnimation()
{
	local name JumpOffEscortAnimation;

	Gatherer(m_Pawn).NotifyJumpingOffProtector();
	JumpOffEscortAnimation = ProtectorEscort.GetGathererJumpOffAnimation();
	PanicAnimHandle = m_Pawn.PlayAnimationOnChannelInstantEaseIn(0, JumpOffEscortAnimation);
	m_Pawn.FinishAnimation(PanicAnimHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function JumpOffProtector()
{
	J0x00:
	// End:0x64 [Loop If]
	if(__NFUN_129__(IsJumpOffPointUsable()))
	{
		log('AI', 4, __NFUN_112__(string(m_Pawn.Name), " - jump off point not usable"));
		yield();
		// [Loop Continue]
		goto J0x00;
		DetachGathererFromProtector();
	}
	Gatherer(m_Pawn).SetIsGettingOffProtector(true);
	ShockAI().BecomePassive();
	PlayJumpOffAnimation();
	DisallowAttachedKeywords();
	Gatherer(m_Pawn).BecomePhysical();
	Gatherer(m_Pawn).NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	Gatherer(m_Pawn).NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	Gatherer(m_Pawn).SetIsGettingOffProtector(false);
	m_Pawn.__NFUN_3970__(4);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

state Running
{Begin:

	ShockAI().PlaySpeech('Panicked');
	ShockAI().SetShouldRun();
	ShockAI().BecomeAggressive();
	MoveToGetPickedUp();
	// End:0xA2
	if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
	{
		JumpOnProtector();
		ShockAI().AddFrozenResistance();
		// End:0xD4
		if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
		{
		}
		yield();
		// [Loop Continue]
		goto J0xA2;
		// End:0x112
		if(__NFUN_130__(IsAttachedToProtector(), __NFUN_114__(ProtectorEscort.GetCurrentGatherer(), m_Pawn)))
		{
		}
		JumpOffProtector();
		// End:0x142
		if(BioshockCharacterGoal(achievingGoal).ShouldFinishUp())
		{
		}
		succeed();
		goto J0x14E;
		fail(1);
		stop;		
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// BadToken (0x50)
	/*@Error*/
}

defaultproperties
{
	ChanceToHaveGathererPickedUpAIAttacker=1.0000000
	ChanceToHaveGathererPickedUpPlayerAttacker=0.5000000
	MaxDistanceToProtector=400.0000000
	MinProtectorHealthPercentage=0.5000000
	bExclusiveAction=true
}