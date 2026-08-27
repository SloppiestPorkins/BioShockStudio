class ActionWaitForGoal extends TyrionScriptAction implements IGoalNotification
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel string goalName;
var travel float TimeOut;
var private float beginTime;
var private int Result;

function OnGoalCompleted(bool bAchieved)
{
	// End:0x1B
	if(bAchieved)
	{
		Result = 0;
		goto J0x26;
		Result = 1;
		return;
	}
	@NULL
	CommanderAction
	J0x26:

	CommanderAction
}

function OnScriptExit()
{
	// End:0x32
	if(parentScript.Level.bIsDLC1Level)
	{
		OnGoalCompleted(false);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function Variable latentExecute()
{
	local ShockAI AI;
	local AI_Goal targetGoal;

	execute();
	Result = -1;
	targetGoal = none;
	// End:0xBD
	foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', AI, Target)
	{
		targetGoal = Class'VengeanceShared.AI_Goal'.static.findGoalByName(AI, goalName);
		// End:0xBC
		if(__NFUN_130__(__NFUN_119__(targetGoal, none), __NFUN_129__(targetGoal.hasCompleted())))
		{
			// End:0xBD
			break;						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1CB
			/*@Error*/
			targetGoal.addNotificationRecipient(self);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x18E
			/*@Error*/
			beginTime = parentScript.Level.TimeSeconds;
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18B
	/*@Error*/
	__NFUN_256__(0.0000000);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x188
	/*@Error*/
	Result = 2;
	goto J0x125;
	goto J0x1AC;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1AC
	/*@Error*/
	__NFUN_256__(0.0000000);
	goto J0x18E;
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(Result));
	return newTemporaryVariable(Class'Scripting.VariableFloat', "0");
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Wait for goal named ", propertyDisplayString('goalName')), " to finish");
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x96
	/*@Error*/
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, ", or timeout in "), string(TimeOut)), " seconds");
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Wait For Goal"
	actionHelp="Waits for a goal to complete or fail, optional timeout period will stop the wait even if the goal has not completed. Returns 0 for success, 1 for failure and 2 for timedout"
	returnType=Class'Scripting.Variable'
	Category="AI"
}