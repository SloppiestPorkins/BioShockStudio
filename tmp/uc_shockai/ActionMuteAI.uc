class ActionMuteAI extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel bool bShouldMuteAI;

function Variable execute()
{
	local ShockAI Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	// End:0x78
	foreach parentScript.allActorLabel(Class'ShockAI.ShockAI', Iter, AILabel)
	{
		Iter.MuteAI(bShouldMuteAI);				
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
	// End:0xAF
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x61
		if(bShouldMuteAI)
		{
			S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will be muted.");
			goto J0xAC;
			S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will be told to start blabbing.");
		}
		goto J0xCE;
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
	actionDisplayName="Mute or UnMute an AI"
	actionHelp="Mute or UnMute an AI"
	Category="AI"
}