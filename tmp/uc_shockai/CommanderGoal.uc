class CommanderGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) ShockPawn CachedScriptedAttackTarget;
var(Parameters) bool bCachedShouldWait;

function ScriptedAttackTarget(ShockPawn Target)
{
	assert(__NFUN_119__(Target, none));
	// End:0x4A
	if(__NFUN_119__(achievingAction, none))
	{
		CommanderAction(achievingAction).ScriptedAttackTarget(Target);
		goto J0x5D;
		CachedScriptedAttackTarget = Target;
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function ScriptedWait()
{
	// End:0x32
	if(__NFUN_119__(achievingAction, none))
	{
		CommanderAction(achievingAction).ScriptedWait();
		goto J0x3E;
		bCachedShouldWait = true;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function ScriptedContinue()
{
	// End:0x32
	if(__NFUN_119__(achievingAction, none))
	{
		CommanderAction(achievingAction).ScriptedContinue();
		goto J0x4B;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x4B
		/*@Error*/
		bCachedShouldWait = false;
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}
