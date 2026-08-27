class ActionSetCollisionAvoidance extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel bool bShouldUseCollisionAvoidance;

function Variable execute()
{
	local ShockAI Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9C
	/*@Error*/
	// End:0x9B
	foreach parentScript.allActorLabel(Class'ShockAI.ShockAI', Iter, AILabel)
	{
		Iter.bAvoidFuturePawnCollisions = bShouldUseCollisionAvoidance;
		Iter.bShouldApplyDisplacement = bShouldUseCollisionAvoidance;				
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
	// End:0xB4
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x6A
		if(bShouldUseCollisionAvoidance)
		{
			S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will avoid other pawns.");
			goto J0xB1;
			S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will NOT avoid other pawns.");
		}
		goto J0xD3;
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
	actionDisplayName="Set Collision Avoidance Status"
	actionHelp="Set Collision Avoidance Status"
	Category="AI"
}