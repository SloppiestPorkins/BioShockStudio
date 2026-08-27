class ActionTellAIToWait extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;

function Variable execute()
{
	local ShockAI Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	// End:0x6E
	foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', Iter, AILabel)
	{
		Iter.ScriptedWait();				
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
	// End:0x5B
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will be told to wait.");
		goto J0x7A;
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
	actionDisplayName="Tell AI To Wait"
	actionHelp="Tell an AI to wait where it is"
	Category="AI"
}