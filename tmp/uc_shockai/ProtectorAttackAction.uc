class ProtectorAttackAction extends CharacterAttackAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private int PickUpGathererAnimationHandle;
var private int ScreamAnimationHandle;
var private int TransitionIntoStateAnimationHandle;
var private float NextTimeShouldNotifyProtectorsAttacking;
var private config float ScreamChance;
var config int ScreamAllowedYawRotationErrorTwoByte;
var private config float TimeBetweenProtectorAttackingNotifications;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Cleanup()
{
	super.Cleanup();
	// End:0x4D
	if(m_Pawn.IsAnimationHandleValid(PickUpGathererAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(PickUpGathererAnimationHandle);
		// End:0x90
		if(m_Pawn.IsAnimationHandleValid(ScreamAnimationHandle))
		{
			m_Pawn.SmartPerTrackEaseOutAnimation(ScreamAnimationHandle);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD3
		/*@Error*/
		m_Pawn.SmartPerTrackEaseOutAnimation(TransitionIntoStateAnimationHandle);
		Protector(m_Pawn).NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	}
	Protector(m_Pawn).NotifyFallDownHitReactionPreventionNoLongerDesired(self);
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

function bool HasAliveGatherer()
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = GetCurrentGatherer();
	return Class'Engine.Pawn'.static.checkAlive(CurrentGatherer);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool GetRotationTowardCurrentGatherer(out Rotator DesiredRotation)
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = Protector(m_Pawn).GetCurrentGatherer();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFC
	/*@Error*/
	assert(__NFUN_119__(CurrentMoveToGoal, none));
	// End:0xC0
	if(__NFUN_132__(CurrentGatherer.IsJumpingOnProtector(), Protector(m_Pawn).IsGathererAttached()))
	{
		DesiredRotation = m_Pawn.Rotation;
		return true;
		goto J0xFC;
		DesiredRotation = Rotator(__NFUN_216__(CurrentGatherer.Location, m_Pawn.Location));
		return true;
		return false;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function bool IsGathererEscortedRotatedCorrectly()
{
	local Gatherer CurrentGatherer;

	CurrentGatherer = GetCurrentGatherer();
	return Class'ShockAI.MoveToAction'.static.IsRotatedTo(CurrentGatherer.Rotation, Rotator(__NFUN_216__(m_Pawn.Location, CurrentGatherer.Location)));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function bool IsGathererAtJumpUpPoint()
{
	local Gatherer CurrentGatherer;
	local Vector GathererJumpUpPoint;

	GathererJumpUpPoint = Protector(m_Pawn).GetGathererJumpUpPoint();
	CurrentGatherer = GetCurrentGatherer();
	return CurrentGatherer.ReachedLocation(GathererJumpUpPoint);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function RotateToGetGatherer()
{
	local name WaitToPickUpGathererAnimation;

	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationTowardCurrentGatherer;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	WaitToPickUpGathererAnimation = Protector(m_Pawn).GetWaitToPickUpGathererAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2BA
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2AD
	/*@Error*/
	// End:0x25F
	if(CurrentMoveToGoal.IsMovementSatisfied())
	{
		// End:0x25C
		if(__NFUN_129__(m_Pawn.IsAnimationHandleValid(PickUpGathererAnimationHandle)))
		{
			PickUpGathererAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, WaitToPickUpGathererAnimation, Class'Engine.Actor'.8);
			goto J0x2AD;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2AD
			/*@Error*/
			m_Pawn.SmartPerTrackEaseOutAnimation(PickUpGathererAnimationHandle);
			PickUpGathererAnimationHandle = 0;
			yield();
			// [Loop Continue]
			goto J0xFF;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2FD
			/*@Error*/
			m_Pawn.SmartPerTrackEaseOutAnimation(PickUpGathererAnimationHandle);
			CurrentMoveToGoal.unPostGoal(self);
		}
		CurrentMoveToGoal.__NFUN_198__();
	}
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function HelpGathererOntoBack()
{
	local Gatherer CurrentGatherer;
	local name PickUpGathererAnimation;

	Protector(m_Pawn).NotifyFullBodyHitReactionPreventionDesired(self);
	Protector(m_Pawn).NotifyFallDownHitReactionPreventionDesired(self);
	// End:0x85
	if(m_Pawn.IsAnimationHandleValid(PickUpGathererAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(PickUpGathererAnimationHandle);
		CurrentGatherer = GetCurrentGatherer();
		assert(__NFUN_119__(CurrentGatherer, none));
		CurrentGatherer.NotifyPlayPickedUpAnimation();
	}
	PickUpGathererAnimation = Protector(m_Pawn).GetPickUpGathererAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14B
	/*@Error*/
	PickUpGathererAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, PickUpGathererAnimation);
	m_Pawn.FinishAnimation(PickUpGathererAnimationHandle);
	Protector(m_Pawn).NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	Protector(m_Pawn).NotifyFallDownHitReactionPreventionNoLongerDesired(self);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function bool CanInteractWithGatherer()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(ShockAI().IsBerserk()), __NFUN_129__(ShockAI().IsBurning())), HasAliveGatherer()), __NFUN_129__(GetCurrentGatherer().IsSaved())), __NFUN_119__(Target, GetCurrentGatherer()));
	return;
	@NULL
}

function PickUpGatherer()
{
	log('AI', 4, __NFUN_112__("Protector(m_Pawn).ShouldPickUpGatherer(): ", string(Protector(m_Pawn).ShouldPickUpGatherer())));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1B4
	/*@Error*/
	RotateToGetGatherer();
	// End:0x173
	if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(GetCurrentGatherer()), __NFUN_129__(Protector(m_Pawn).IsGathererAttached())))
	{
		// End:0x15B
		if(__NFUN_130__(Protector(m_Pawn).CanPickUpGatherer(), GetCurrentGatherer().CanJumpOntoProtector()))
		{
			HelpGathererOntoBack();
			goto J0x173;
			GetCurrentGatherer().CancelJumpOntoProtector();
			Protector(m_Pawn).SetNextTimeCanPickUpGatherer();
		}
		Protector(m_Pawn).SetCanPickUpGatherer(false);
	}
	return;
	@NULL
	EcologyAI
	BioshockMovementAction
	@NULL
}

function NotifyBeginningAttack()
{
	super.NotifyBeginningAttack();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x41
	/*@Error*/
	ScreamAtTarget();
	return;
	@NULL
	EcologyAI
}

function bool GetRotationTowardsAttackTarget(out Rotator DesiredRotation)
{
	DesiredRotation = Rotator(__NFUN_216__(Target.Location, m_Pawn.Location));
	return true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ScreamAtTarget()
{
	assert(__NFUN_114__(CurrentMoveToGoal, none));
	CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	construct_AI_ResourceIntVectorBool(movementResource(), achievingGoal.Priority, m_Pawn.Location);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = GetRotationTowardsAttackTarget;
	CurrentMoveToGoal.SetShouldNeverSucceed(true);
	CurrentMoveToGoal.postGoal(self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14D
	/*@Error*/
	yield();
	// [Loop Continue]
	goto J0xD5;
	PlayScreamAnimation();
	CurrentMoveToGoal.unPostGoal(self);
	CurrentMoveToGoal.__NFUN_198__();
	CurrentMoveToGoal = none;
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayScreamAnimation()
{
	local name ScreamAnimation;

	ScreamAnimation = Protector(m_Pawn).GetScreamAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEE
	/*@Error*/
	ScreamAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ScreamAnimation);
	ShockAI().SetMotionModifier_MeleeAttack(ScreamAnimationHandle, Rotator(__NFUN_216__(Target.Location, m_Pawn.Location)).Yaw);
	m_Pawn.FinishAnimation(ScreamAnimationHandle);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
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

function NotifyAttackCompleted()
{
	super.NotifyAttackCompleted();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x32
	/*@Error*/
	TransitionIntoPassive();
	return;
	@NULL
}

defaultproperties
{
	ScreamAllowedYawRotationErrorTwoByte=8192
	TimeBetweenProtectorAttackingNotifications=1.5000000
}