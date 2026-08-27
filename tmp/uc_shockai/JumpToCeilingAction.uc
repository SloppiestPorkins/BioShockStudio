class JumpToCeilingAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Vector StartLocation;
var private int JumpAnimationHandle;
var private bool bFinishedJumpingToCeiling;
var private config float DesiredVelocityToReachCeiling;
var config array<name> JumpToCeilingInitialAnimations;
var config array<name> JumpToCeilingTravelAnimations;
var config array<name> JumpToCeilingEndAnimations;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	ShockAI().NotifyFullBodyHitReactionPreventionDesired(self);
	ShockAI().NotifyQuickHitReactionPreventionDesired(self);
	ShockAI().NotifyEventReactionPreventionDesired(self);
	EcologyAI(m_Pawn).NotifyDouseReactionPreventionDesired(self);
	ShockAI().AddFrozenResistance();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	ShockAI().NotifyFullBodyHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyQuickHitReactionPreventionNoLongerDesired(self);
	ShockAI().NotifyEventReactionPreventionNoLongerDesired(self);
	EcologyAI(m_Pawn).NotifyDouseReactionPreventionNoLongerDesired(self);
	ShockAI().RemoveFrozenResistance();
	CleanupJumpingToCeiling();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function CleanupJumpingToCeiling()
{
	// End:0x76
	if(__NFUN_129__(bFinishedJumpingToCeiling))
	{
		// End:0x40
		if(m_Pawn.bUseLocalGravityDirection)
		{
			m_Pawn.ClearLocalGravityDirection();
			ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.-1);
		}
		goto J0xBD;
		ShockAI().NotifyCeilingVisionDesired();
	}
	ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.0);
	// End:0x100
	if(m_Pawn.IsAnimationHandleValid(JumpAnimationHandle))
	{
		m_Pawn.SmartPerTrackEaseOutAnimation(JumpAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15A
		/*@Error*/
	}
	m_Pawn.__NFUN_3970__(2);
	ShockAI().ResetIdling();
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	ShockAI().RemoveFrozenResistance();
	CleanupJumpingToCeiling();
	return;
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ShockAI().AddFrozenResistance();
	return;
	@NULL
}

function Vector FindJumpUpLocation()
{
	local Vector EndTracePoint, HitLocation, HitNormal;

	EndTracePoint = m_Pawn.Location;
	__NFUN_184__(EndTracePoint.Z, JumpToCeilingGoal(achievingGoal).MaximumCeilingHeight);
	m_Pawn.__NFUN_277__(HitLocation, HitNormal, EndTracePoint, m_Pawn.Location, false, m_Pawn.GetCylinderExtent());
	return HitLocation;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function JumpUp()
{
	local Vector JumpVelocity, StartLocation, JumpUpLocation;
	local float ExpectedTime, StartTime, JumpDistance, TravelAnimLength;
	local name JumpAnimation;

	ShockAI().PlaySpeech('Jumped');
	JumpAnimation = JumpToCeilingInitialAnimations[__NFUN_167__(JumpToCeilingInitialAnimations.Length)];
	JumpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, JumpAnimation, Class'Engine.Actor'.4);
	m_Pawn.FinishAnimation(JumpAnimationHandle);
	JumpUpLocation = FindJumpUpLocation();
	JumpDistance = __NFUN_186__(__NFUN_175__(JumpUpLocation.Z, m_Pawn.Location.Z));
	StartTime = Level().TimeSeconds;
	StartLocation = m_Pawn.Location;
	JumpVelocity.Z = __NFUN_193__(__NFUN_175__(__NFUN_171__(DesiredVelocityToReachCeiling, DesiredVelocityToReachCeiling), __NFUN_171__(__NFUN_171__(float(2), m_Pawn.PhysicsVolume.Gravity.Z), JumpDistance)));
	ExpectedTime = __NFUN_172__(__NFUN_175__(JumpVelocity.Z, DesiredVelocityToReachCeiling), __NFUN_169__(m_Pawn.PhysicsVolume.Gravity.Z));
	JumpAnimation = JumpToCeilingTravelAnimations[__NFUN_167__(JumpToCeilingTravelAnimations.Length)];
	TravelAnimLength = m_Pawn.GetAnimationLength(JumpAnimation);
	JumpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, JumpAnimation, Class'Engine.Actor'.4);
	m_Pawn.InstantPerTrackEaseInAnimation(JumpAnimationHandle);
	m_Pawn.SetAnimationPlaybackRate(JumpAnimationHandle, __NFUN_172__(TravelAnimLength, ExpectedTime));
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), " JumpUp - JumpVelocity is: "), string(JumpVelocity)), " ExpectedTime: "), string(ExpectedTime)), " TravelAnimLength: "), string(TravelAnimLength)), " Anim Rate: "), string(__NFUN_172__(TravelAnimLength, ExpectedTime))));
	ShockAI().ShouldNotTakeDamageOnNextLanding = true;
	m_Pawn.__NFUN_3970__(4);
	m_Pawn.AddVelocity(JumpVelocity);
	__NFUN_256__(ExpectedTime);
	m_Pawn.SetLocalGravityDirection(vect(0.0000000, 0.0000000, 1.0000000));
	m_Pawn.__NFUN_3970__(2);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x46D
	/*@Error*/
	yield();
	goto J0x444;
	ShockAI().ResetIdling();
	ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.0);
	ShockAI().PlaySpeech('Landed');
	JumpAnimation = JumpToCeilingEndAnimations[__NFUN_167__(JumpToCeilingEndAnimations.Length)];
	JumpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, JumpAnimation);
	m_Pawn.InstantPerTrackEaseInAnimation(JumpAnimationHandle);
	m_Pawn.FinishAnimation(JumpAnimationHandle);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function TeleportToCeiling()
{
	local Vector PointOnCeiling;

	PointOnCeiling = FindJumpUpLocation();
	m_Pawn.__NFUN_267__(PointOnCeiling);
	m_Pawn.SetLocalGravityDirection(vect(0.0000000, 0.0000000, 1.0000000));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x3A
	if(ShockAI(m_Pawn).IsUsingLowDetailMovement())
	{
		TeleportToCeiling();
		yield();
		goto J0x44;
		JumpUp();
	}
	bFinishedJumpingToCeiling = true;
	J0x44:

	succeed();
	stop;	
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	DesiredVelocityToReachCeiling=1300.0000000
	JumpToCeilingInitialAnimations[0]="CR_JumpToCeilingBegin"
	JumpToCeilingTravelAnimations[0]="CR_JumpToCeilingTravel"
	JumpToCeilingEndAnimations[0]="CR_JumpToCeilingEnd"
	satisfiesGoal=Class'ShockAI.JumpToCeilingGoal'
}