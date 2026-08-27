class BotBeDormantAction extends BotBehaviorActionInterface
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) bool NeverDie;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super.initAction(R, Goal);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x74
	/*@Error*/
	MyBot.TriggerEffectEvent('DormantAndHackable');
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x88
	/*@Error*/
	// End:0x68
	if(MyBot.IsAlive())
	{
		MyBot.CancelDyingTimer();
		MyBot.UnTriggerEffectEvent('DormantAndHackable');
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

state Running
{Begin:

	log('AI_Security', 4, __NFUN_112__(string(Name), " is now running BotBeDormantAction."));
	MyBot.SetVisionState(false);
	__NFUN_256__(MyBot.GetRandomSecuritySystemShutdownDormantDelay());
	MyBot.ShutdownEverything();
	MyBot.TriggerEffectEvent('WentDormant');
	// End:0x100
	if(__NFUN_129__(NeverDie))
	{
		MyBot.SetDyingStateTime(MyBot.GetDormantDuration());
		MyBot.__NFUN_113__('Dying');
		MyBot.LimitNumberOfDormantSecurityBots(MyBot);
		stop;						
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
	satisfiesGoal=Class'ShockAI.BotBeDormantGoal'
}