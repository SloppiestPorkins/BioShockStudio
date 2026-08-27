class ActionToggleAIReactions extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum EToggleHitReactions
{
	DoNotChange,                    // 0
	Use,                            // 1
	DoNotUse                        // 2
};

var travel name AILabel;
var travel ActionToggleAIReactions.EToggleHitReactions FullBodyHitReactions;
var travel ActionToggleAIReactions.EToggleHitReactions QuickHitReactions;
var travel ActionToggleAIReactions.EToggleHitReactions FallDownHitReactions;
var travel ActionToggleAIReactions.EToggleHitReactions EventReactions;
var travel ActionToggleAIReactions.EToggleHitReactions BurningAnimations;
var travel ActionToggleAIReactions.EToggleHitReactions BurningBehavior;
var travel ActionToggleAIReactions.EToggleHitReactions DouseBehavior;
var travel ActionToggleAIReactions.EToggleHitReactions InsectSwarmAnimations;
var travel ActionToggleAIReactions.EToggleHitReactions InsectSwarmBehavior;

function bool ShouldChange(ActionToggleAIReactions.EToggleHitReactions ToggleHitReactions)
{
	return __NFUN_155__(int(ToggleHitReactions), int(0));
	return;
	@NULL
}

function bool GetChangeValue(ActionToggleAIReactions.EToggleHitReactions ToggleHitReactions)
{
	assert(__NFUN_155__(int(ToggleHitReactions), int(0)));
	return __NFUN_154__(int(ToggleHitReactions), int(1));
	return;
	@NULL
	CommanderAction
}

function Variable execute()
{
	local ShockAI TargetAI;
	local bool ChangeResult;

	super.execute();
	// End:0x364
	foreach parentScript.allActorLabel(Class'ShockAI.ShockAI', TargetAI, AILabel)
	{
		// End:0x94
		if(ShouldChange(FullBodyHitReactions))
		{
			ChangeResult = GetChangeValue(FullBodyHitReactions);
			TargetAI.SetScriptedUseFullBodyHitReactions(ChangeResult);
			// End:0xE9
			if(ShouldChange(QuickHitReactions))
			{
				ChangeResult = GetChangeValue(QuickHitReactions);
				TargetAI.SetScriptedUseQuickHitReactions(ChangeResult);
			}
			// End:0x13E
			if(ShouldChange(FallDownHitReactions))
			{
				ChangeResult = GetChangeValue(FallDownHitReactions);
				TargetAI.SetScriptedUseFallDownHitReactions(ChangeResult);
			}
			// End:0x193
			if(ShouldChange(EventReactions))
			{
				ChangeResult = GetChangeValue(EventReactions);
				TargetAI.SetScriptedUseEventReactions(ChangeResult);
				// End:0x1E8
				if(ShouldChange(BurningAnimations))
				{
					ChangeResult = GetChangeValue(BurningAnimations);
				}
				TargetAI.SetShouldUseBurningAnimations(ChangeResult);
				// End:0x23D
				if(ShouldChange(BurningBehavior))
				{
					ChangeResult = GetChangeValue(BurningBehavior);
				}
				TargetAI.SetShouldDoBurningBehavior(ChangeResult);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x2B9
				/*@Error*/
				ChangeResult = GetChangeValue(DouseBehavior);
			}
			EcologyAI(TargetAI).SetCanDouse(ChangeResult);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x30E
			/*@Error*/
			ChangeResult = GetChangeValue(InsectSwarmAnimations);
			TargetAI.SetShouldUseInsectSwarmAnimations(ChangeResult);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x363
		/*@Error*/
		ChangeResult = GetChangeValue(InsectSwarmBehavior);
		TargetAI.SetShouldUseInsectSwarmBehavior(ChangeResult);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0x64
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__("Toggling an AI with label ", string(AILabel)), "'s reaction values.");
		goto J0x83;
		S = "AILabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable or disable reactions from an AI"
	actionHelp="Enable or disable reactions from an AI"
	Category="AI"
}