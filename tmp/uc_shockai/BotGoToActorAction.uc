class BotGoToActorAction extends BotBaseSubAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor targetActor;
var(Parameters) float LookAtActorDistance;
var private BotNavigateToActorLocationMovementGoal CurrentMoveGoal;
var private SecurityBot MyBot;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyBot = SecurityBot(m_Pawn);
	assert(__NFUN_119__(MyBot, none));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	// End:0x29
	if(__NFUN_119__(CurrentMoveGoal, none))
	{
		CurrentMoveGoal.__NFUN_198__();
		CurrentMoveGoal = none;
		super(AI_CharacterAction).Cleanup();
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function InitializeMovement()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xAB
	/*@Error*/
	StopAllMovement();
	assert(__NFUN_114__(CurrentMoveGoal, none));
	CurrentMoveGoal = Class'ShockAI.BotNavigateToActorLocationMovementGoal'.static.Allocate(self).;
	construct_AI_ResourceActorFloat(characterResource(), targetActor, LookAtActorDistance);
	assert(__NFUN_119__(CurrentMoveGoal, none));
	CurrentMoveGoal.__NFUN_199__();
	CurrentMoveGoal.postGoal(self);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function StopAllMovement()
{
	// End:0x41
	if(__NFUN_119__(CurrentMoveGoal, none))
	{
		CurrentMoveGoal.unPostGoal(self);
		CurrentMoveGoal.__NFUN_198__();
		CurrentMoveGoal = none;
		return;
		@NULL
		CommanderAction
		BioshockMovementAction
	}
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(MyBot.Name), " running BotGoToActorAction."));
	MyBot.SwitchToMotion(0);
	InitializeMovement();
	// End:0xC3
	if(__NFUN_119__(CurrentMoveGoal, none))
	{
		waitForGoal_AI_Goal(CurrentMoveGoal);
		// End:0xB4
		if(CurrentMoveGoal.wasAchieved())
		{
			succeed();
			goto J0xC0;
			fail(1);
			goto J0xCF;
			fail(1);
			stop;
		}								
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.BotGoToActorGoal'
}