class ActionSetCorpseFadeoutTime extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel float FadeOutDuration;

function Variable execute()
{
	local ShockAI Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x78
	/*@Error*/
	// End:0x77
	foreach parentScript.allActorLabel(Class'ShockAI.ShockAI', Iter, AILabel)
	{
		Iter.FadeOutAndDestroy(FadeOutDuration);				
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
	// End:0x76
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will be fade out over "), string(FadeOutDuration)), " seconds.");
		goto J0x95;
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
	FadeOutDuration=3.0000000
	actionDisplayName="Fadeout and Destroy an AI"
	actionHelp="Fadeout and Destroy an AI"
	Category="AI"
}