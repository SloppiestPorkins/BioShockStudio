class ActionToggleAIAttacking extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel bool bCanAttack;

function Variable execute()
{
	local EcologyFighter Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	// End:0x78
	foreach parentScript.dynamicActorLabel(Class'ShockAI.EcologyFighter', Iter, AILabel)
	{
		Iter.SetCanAttack(bCanAttack);				
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
	// End:0xB7
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will ");
		// End:0x84
		if(bCanAttack)
		{
			S = __NFUN_112__(S, "be allowed to attack.");
			goto J0xB4;
			S = __NFUN_112__(S, "not be allowed to attack.");
		}
		goto J0xD6;
		S = "AILabel is not set!";
		return;
		J0xB4:

		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Toggle whether an AI can attack or not"
	actionHelp="Toggle whether an AI can attack or not"
	Category="AI"
}