class FullBodyReactionAction extends BioshockCharacterAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn.EDamageEvent DamageEvent;
var(Parameters) Vector HitLocation;
var(Parameters) Vector HitNormal;
var(Parameters) Vector HitImpulseDirection;
var(Parameters) float HitMomentumImparted;
var(Parameters) float MomentumScale;
var(Parameters) name HitLowBone;
var(Parameters) name HitHighBone;
var(Parameters) DamageStimuliSetState HitDamageStimuliSetState;
var private int FullBodyReactionAnimationHandle;
var private float TimeToSleep;
var config float HitFrontOrBackDegrees;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	m_Pawn = R.Pawn();
	assert(__NFUN_119__(m_Pawn, none));
	ShockAI(m_Pawn).StopAnyWeaponAction();
	ShockAI().StopAnyScriptedLoopingAnimations();
	PlayFullBodyReactionAnimation();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D
	/*@Error*/
	m_Pawn.SmartPerTrackEaseOutAnimation(FullBodyReactionAnimationHandle);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float selectionHeuristic(AI_Goal Goal)
{
	local ShockAI AI;

	assert(Goal.__NFUN_303__('ReactToDamageGoal'));
	AI = ShockAI(Goal.resource.Pawn());
	assert(__NFUN_119__(AI, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF2
	/*@Error*/
	return 1.0000000;
	goto J0xF8;
	return 0.0000000;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
	@NULL
}

function PlayFullBodyReactionAnimation()
{
	local name AnimationName;
	local float FullBodyAnimLength;

	AnimationName = ShockAI(m_Pawn).GetFullBodyHitAnimation(HitNormal, HitFrontOrBackDegrees, HitHighBone);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xEB
	/*@Error*/
	Class'ShockAI.MoveToAction'.static.SendStopLocomotionRequest(m_Pawn);
	FullBodyReactionAnimationHandle = m_Pawn.PlayAnimationOnChannel(0, AnimationName);
	FullBodyAnimLength = m_Pawn.GetAnimationLengthScaled(FullBodyReactionAnimationHandle);
	TimeToSleep = __NFUN_175__(FullBodyAnimLength, 0.2500000);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x2F
	if(m_Pawn.IsAnimationHandleValid(FullBodyReactionAnimationHandle))
	{
		__NFUN_256__(TimeToSleep);
		succeed();
		stop;				
	}
	@NULL
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	HitFrontOrBackDegrees=45.0000000
	satisfiesGoal=Class'ShockAI.ReactToDamageGoal'
	bExclusiveAction=true
}