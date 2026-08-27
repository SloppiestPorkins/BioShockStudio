class EcologyCommanderAction extends CommanderAction
	native
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private DouseGoal CurrentDouseGoal;

function Cleanup()
{
	super.Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentDouseGoal, none))
	{
		CurrentDouseGoal.__NFUN_198__();
		CurrentDouseGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function goalAchievedCB(AI_Goal Goal, AI_Action Child)
{
	super(AI_Action).goalAchievedCB(Goal, Child);
	assert(__NFUN_119__(Goal, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x74
	/*@Error*/
	CurrentDouseGoal.unPostGoal(self);
	CurrentDouseGoal.__NFUN_198__();
	CurrentDouseGoal = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function goalNotAchievedCB(AI_Goal Goal, AI_Action Child, ActionBase.ACT_ErrorCodes errorCode)
{
	super(AI_Action).goalNotAchievedCB(Goal, Child, errorCode);
	assert(__NFUN_119__(Goal, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7D
	/*@Error*/
	CurrentDouseGoal.unPostGoal(self);
	CurrentDouseGoal.__NFUN_198__();
	CurrentDouseGoal = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleAIEventNotification(AIEventNotification Event)
{
	local EventReactionGoal ReactionGoal;

	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), "::EcologyCommanderAction received an AIEventNotification.  Type = "), string(Event.NotificationType)), ", Location = "), string(Event.GetLocation())));
	ReactionGoal = Class'ShockAI.EventReactionGoal'.static.Allocate(self).;
	construct_AI_ResourceAIEventNotification(characterResource(), Event);
	ReactionGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function HandleAIAttackNotification(Actor Attacker, float InitiateDamageDelay, DamageStimuliSet.EDamageType DamageType)
{
	local AttackReactionGoal ReactionGoal;

	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(m_Pawn.Name), "::EcologyCommanderAction received an AIAttackNotification call.  Attacking actor = "), string(Attacker)), "."));
	ReactionGoal = Class'ShockAI.AttackReactionGoal'.static.Allocate(self).;
	construct_AI_ResourceActorFloatByte(characterResource(), Attacker, InitiateDamageDelay, DamageType);
	ReactionGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function CreateBurningBehavior()
{
	super.CreateBurningBehavior();
	// End:0x3A
	if(EcologyAI(m_Pawn).ShouldDouse())
	{
		DouseInWater();
		goto J0x44;
		super.CreateBurningBehavior();
		return;
		@NULL
	}
	CommanderAction
	BioshockMovementAction
	@NULL
}

function DouseInWater()
{
	// End:0x79
	if(__NFUN_130__(__NFUN_119__(CurrentDouseGoal, none), __NFUN_132__(CurrentDouseGoal.hasCompleted(), CurrentDouseGoal.hasExpired())))
	{
		CurrentDouseGoal.unPostGoal(self);
		CurrentDouseGoal.__NFUN_198__();
		CurrentDouseGoal = none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11E
		/*@Error*/
		CurrentDouseGoal = Class'ShockAI.DouseGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceShockPawn(characterResource(), ShockAI().GetAttackTarget());
	CurrentDouseGoal.__NFUN_199__();
	CurrentDouseGoal.setExpirationTime(0.0000000);
	CurrentDouseGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}
