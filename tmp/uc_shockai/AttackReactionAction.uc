class AttackReactionAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor Attacker;
var(Parameters) float InitiateDamageDelay;
var(Parameters) DamageStimuliSet.EDamageType DamageType;
var private EcologyAI MyAI;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyAI = EcologyAI(m_Pawn);
	assert(__NFUN_119__(MyAI, none));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	ShockAI().AddLocomotionKeyword('ReactToAttack', Class'ShockAI.ShockAI'.-1);
	return;
	@NULL
	CommanderAction
}

function NotifyPausedDueToExclusivity()
{
	super(AI_RunnableAction).NotifyPausedDueToExclusivity();
	instantSucceed();
	return;
	@NULL
}

function React()
{
	local name AnimationName;
	local float animationLength, AnimationDelay;

	AnimationName = MyAI.GetAttackReactionAnimation(Attacker, DamageType);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD0
	/*@Error*/
	animationLength = MyAI.GetAnimationLength(AnimationName);
	AnimationDelay = __NFUN_175__(InitiateDamageDelay, animationLength);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAF
	/*@Error*/
	__NFUN_256__(AnimationDelay);
	MyAI.PlayAnimationOnChannel(0, AnimationName);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

function RespondToAttack()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB0
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB0
	/*@Error*/
	EcologyFighter(MyAI).AddForcedEnemy(ShockPawn(Attacker));
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

state Running
{Begin:

	// End:0x70
	if(__NFUN_130__(__NFUN_130__(__NFUN_119__(MyAI, none), MyAI.CanSee(Attacker)), MyAI.CanReactToAttack()))
	{
		bExclusiveAction = true;
		React();
		RespondToAttack();
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
	satisfiesGoal=Class'ShockAI.AttackReactionGoal'
}