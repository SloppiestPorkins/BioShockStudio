class CharacterMoveToAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor DestinationActor;
var(Parameters) bool bShouldNeverSucceed;
var(Parameters) bool bShouldBeAggressive;
var(Parameters) bool bShouldRun;
var MoveToGoal CurrentMoveToGoal;

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	// End:0x33
	if(__NFUN_119__(CurrentMoveToGoal, none))
	{
		CurrentMoveToGoal.__NFUN_198__();
		CurrentMoveToGoal = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function NotifyRunningDueToExclusivity()
{
	super(AI_RunnableAction).NotifyRunningDueToExclusivity();
	ResetState();
	return;
	@NULL
}

function ResetState()
{
	// End:0x28
	if(bShouldBeAggressive)
	{
		ShockAI().BecomeAggressive();
		goto J0x40;
		ShockAI().BecomePassive();
	}
	// End:0x80
	if(bShouldRun)
	{
		ShockAI().BecomeAggressive();
		ShockAI().SetShouldRun();
		goto J0x98;
		ShockAI().SetShouldWalk();
	}
	return;
	@NULL
	CommanderAction
}

state Running
{Begin:

	useResources(Class'VengeanceShared.AI_Resource'.2);
	ResetState();
	// End:0x131
	if(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0)))
	{
		m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(true);
		// End:0x10B
		if(__NFUN_155__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(0)))
		{
			// End:0xFE
			if(__NFUN_154__(int(m_Pawn.GetRagdoll().GetRagdollState()), int(2)))
			{
				m_Pawn.GetRagdoll().Rise();
				yield();
				// [Loop Continue]
				goto J0x79;
				m_Pawn.GetRagdoll().SetRisePoseMatchingEnabled(false);
			}
		}
		CurrentMoveToGoal = Class'ShockAI.MoveToGoal'.static.Allocate(self).;
	}
	construct_AI_ResourceIntActor(movementResource(), achievingGoal.Priority, DestinationActor);
	CurrentMoveToGoal.__NFUN_199__();
	CurrentMoveToGoal.__GetDesiredRotationOverride__Delegate = CharacterMoveToGoal(achievingGoal).GetDesiredRotationOverride;
	CurrentMoveToGoal.SetShouldNeverSucceed(bShouldNeverSucceed);
	waitForGoal_AI_Goal(CurrentMoveToGoal.postGoal(self));
	succeed();
	stop;		
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
	satisfiesGoal=Class'ShockAI.CharacterMoveToGoal'
	bExclusiveAction=true
}