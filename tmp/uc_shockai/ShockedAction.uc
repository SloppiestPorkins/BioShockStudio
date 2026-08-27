class ShockedAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) bool bGoRagdollFirst;
var private int ShockedAnimationHandle;
var private bool HitMomentumInfoValid;
var Vector HitLocation;
var Vector HitNormal;
var Vector HitImpulseDirection;
var float HitMomentumImparted;
var float MomentumScale;
var name HitLowBone;
var name HitHighBone;
var DamageStimuliSetState HitDamageStimuliSetState;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	ShockAI().StopSpeech('Shocked');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6E
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(ShockedAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(ShockedAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	// End:0x84
	if(ShockAI().IsShocked())
	{
		// End:0x62
		if(__NFUN_154__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0)))
		{
			PlayShockedAnimation();
			goto J0x84;
			bGoRagdollFirst = true;
		}
		__NFUN_113__('None');
		__NFUN_113__('Running');
		return;
		@NULL
		CommanderAction
	}
	J0x84:

	CommanderAction
}

function FallDown(Vector inHitLocation, Vector inHitNormal, Vector inHitImpulseDirection, float inHitMomentumImparted, name inHitLowBone, name inHitHighBone, DamageStimuliSet inDamageStimuli)
{
	HitLocation = inHitLocation;
	HitNormal = inHitNormal;
	HitImpulseDirection = inHitImpulseDirection;
	HitMomentumImparted = inHitMomentumImparted;
	HitLowBone = inHitLowBone;
	HitHighBone = inHitHighBone;
	HitDamageStimuliSetState = inDamageStimuli.GetState();
	HitMomentumInfoValid = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDC
	/*@Error*/
	ApplyFallDownMomentum();
	goto J0xFE;
	bGoRagdollFirst = true;
	__NFUN_113__('None');
	__NFUN_113__('Running');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ApplyFallDownMomentum()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5E
	/*@Error*/
	Class'ShockAI.FallDownReactionAction'.static.ApplyDeferredMomentum(ShockAI(), HitDamageStimuliSetState, HitImpulseDirection, HitLocation, HitLowBone);
	HitMomentumInfoValid = false;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function Fall()
{
	local Aggressor AggressorAI;

	// End:0x7C
	if(m_Pawn.IsOnCeiling())
	{
		m_Pawn.ClearLocalGravityDirection();
		ShockAI().AddLocomotionKeyword('Ceiling', Class'ShockAI.ShockAI'.-1);
		ShockAI().NotifyCeilingVisionNoLongerDesired();
		m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(false);
	}
	m_Pawn.GetRagdoll().SetMotorsEnabled(true);
	m_Pawn.GetRagdoll().Fall();
	ApplyFallDownMomentum();
	// End:0x166
	if(__NFUN_130__(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(2)), __NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0))))
	{
		yield();
		// [Loop Continue]
		goto J0xF7;
		PlayShockedAnimation();
		// End:0x1A2
		if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
		{
		}
		yield();
		// [Loop Continue]
		goto J0x170;
		m_Pawn.SmartPerTrackEaseOutAnimation(ShockedAnimationHandle);
		m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(true);
	}
	m_Pawn.ForcePoseUpdate();
	// End:0x291
	if(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0)))
	{
		// End:0x284
		if(__NFUN_154__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(2)))
		{
			m_Pawn.GetRagdoll().Rise();
			yield();
			// [Loop Continue]
			goto J0x1FF;
			m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(false);
			m_Pawn.GetRagdoll().SetMotorsEnabled(false);
		}
		m_Pawn.GetAnchor();
	}
	AggressorAI = Aggressor(m_Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x353
	/*@Error*/
	AggressorAI.SetIsMimic(false);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function PlayShockedAnimation()
{
	local name ShockedAnimationName;

	ShockedAnimationName = ShockAI().GetShockedAnimation();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x73
	/*@Error*/
	ShockedAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, ShockedAnimationName, Class'Engine.Actor'.8);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x11C
	if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
	{
		ShockAI().PlaySpeech('Shocked');
		ShockAI(m_Pawn).StopAnyWeaponAction();
		// End:0xAF
		if(__NFUN_132__(bGoRagdollFirst, __NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0))))
		{
			Fall();
			bGoRagdollFirst = false;
			// End:0xEA
			if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
			{
			}
			PlayShockedAnimation();
			// End:0x11C
			if(__NFUN_129__(BioshockCharacterGoal(achievingGoal).ShouldFinishUp()))
			{
				yield();
			}
			// [Loop Continue]
			goto J0xEA;
			succeed();
			stop;			
			@NULL
			@NULL
		}
	}
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.ShockedGoal'
	bExclusiveAction=true
}