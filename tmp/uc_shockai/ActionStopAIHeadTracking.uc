class ActionStopAIHeadTracking extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;

function Variable execute()
{
	local ShockAI AI;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	// End:0x6E
	foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', AI, AILabel)
	{
		AI.StopTracking();				
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
	// End:0x69
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will be told to stop head tracking.");
		goto J0x88;
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
	actionDisplayName="Stop AI Head Tracking"
	actionHelp="Stop AI Head Tracking"
	Category="AI"
}