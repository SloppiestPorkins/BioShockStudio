class JumpToFloorAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private Vector StartLocation;
var private int JumpAnimationHandle;
var private bool bFinishedJumpingToFloor;
var config float MaximumCeilingHeight;
var config array<name> JumpToFloorInitialAnimations;
var config array<name> JumpToFloorTravelAnimations;
var config array<name> JumpToFloorEndAnimations;

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
	CleanupJumpingToFloor();
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function CleanupJumpingToFloor()
{
	ShockAI().NotifyCeilingVisionNoLongerDesired();
	ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.-1);
	// End:0x8B
	if(__NFUN_129__(bFinishedJumpingToFloor))
	{
		// End:0x8B
		if(m_Pawn.bUseLocalGravityDirection)
		{
			m_Pawn.ClearLocalGravityDirection();
			// End:0xCE
			if(m_Pawn.IsAnimationHandleValid(JumpAnimationHandle))
			{
			}
		}
		m_Pawn.SmartPerTrackEaseOutAnimation(JumpAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x128
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

function Vector FindDropDownLocation()
{
	local Vector EndTracePoint, HitLocation, HitNormal;

	EndTracePoint = m_Pawn.Location;
	__NFUN_185__(EndTracePoint.Z, MaximumCeilingHeight);
	m_Pawn.__NFUN_277__(HitLocation, HitNormal, EndTracePoint, m_Pawn.Location, false, m_Pawn.GetCylinderExtent());
	return HitLocation;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DropDown()
{
	local Vector DropDownLocation;
	local float DropDistance, ExpectedTime, StartTime, TravelAnimLength;
	local name JumpAnimation;

	ShockAI().PlaySpeech('Jumped');
	JumpAnimation = JumpToFloorInitialAnimations[__NFUN_167__(JumpToFloorInitialAnimations.Length)];
	JumpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, JumpAnimation, Class'Engine.Actor'.4);
	m_Pawn.FinishAnimation(JumpAnimationHandle);
	StartTime = Level().TimeSeconds;
	DropDownLocation = FindDropDownLocation();
	DropDistance = __NFUN_169__(__NFUN_186__(__NFUN_175__(m_Pawn.Location.Z, DropDownLocation.Z)));
	ExpectedTime = __NFUN_172__(__NFUN_193__(__NFUN_171__(__NFUN_171__(2.0000000, m_Pawn.PhysicsVolume.Gravity.Z), DropDistance)), __NFUN_169__(m_Pawn.PhysicsVolume.Gravity.Z));
	JumpAnimation = JumpToFloorTravelAnimations[__NFUN_167__(JumpToFloorTravelAnimations.Length)];
	TravelAnimLength = m_Pawn.GetAnimationLength(JumpAnimation);
	JumpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, JumpAnimation, Class'Engine.Actor'.4);
	m_Pawn.InstantPerTrackEaseInAnimation(JumpAnimationHandle);
	m_Pawn.SetAnimationPlaybackRate(JumpAnimationHandle, __NFUN_172__(TravelAnimLength, ExpectedTime));
	m_Pawn.ClearLocalGravityDirection();
	m_Pawn.__NFUN_3970__(4);
	ShockAI().ShouldNotTakeDamageOnNextLanding = true;
	__NFUN_256__(ExpectedTime);
	ShockAI().ResetIdling();
	ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.-1);
	ShockAI().PlaySpeech('Landed');
	JumpAnimation = JumpToFloorEndAnimations[__NFUN_167__(JumpToFloorEndAnimations.Length)];
	JumpAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, JumpAnimation);
	m_Pawn.InstantPerTrackEaseInAnimation(JumpAnimationHandle);
	m_Pawn.FinishAnimation(JumpAnimationHandle);
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function TeleportToFloor()
{
	local Vector PointOnFloor;

	PointOnFloor = FindDropDownLocation();
	m_Pawn.__NFUN_267__(PointOnFloor);
	m_Pawn.ClearLocalGravityDirection();
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
		TeleportToFloor();
		yield();
		goto J0x44;
		DropDown();
	}
	bFinishedJumpingToFloor = true;
	J0x44:

	succeed();
	stop;	
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	MaximumCeilingHeight=3000.0000000
	JumpToFloorInitialAnimations[0]="CR_JumpToFloorBegin"
	JumpToFloorTravelAnimations[0]="CR_JumpToFloorTravel"
	JumpToFloorEndAnimations[0]="CR_JumpToFloorEnd"
	satisfiesGoal=Class'ShockAI.JumpToFloorGoal'
}