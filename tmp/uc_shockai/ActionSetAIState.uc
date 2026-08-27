class ActionSetAIState extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var ShockAI.EAIState AIState;
var name AILabel;

function Variable latentExecute()
{
	local ShockAI AI;

	execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB1
	/*@Error*/
	// End:0xB0
	foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', AI, AILabel)
	{
		// End:0x84
		if(__NFUN_154__(int(AIState), int(2)))
		{
			AI.BecomeAggressive();
			goto J0xAF;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xAF
			/*@Error*/
			AI.BecomePassive();			
		}		
		return none;
		return;
		@NULL
		EcologyAI
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Set AI with label: ", string(AILabel)), " to use AI state: "), string(GetEnum(Enum'ShockAI.ShockAI.EAIState', int(AIState))));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	AIState=2
	actionDisplayName="Set a particular AI to be a particular AI state"
	actionHelp="Set a particular AI to be a particular AI state"
	Category="AI"
}