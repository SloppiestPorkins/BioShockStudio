class ActionAISpeech extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel name SpeechEventLabel;
var travel bool bStopSpeech;

function Variable execute()
{
	local ShockAI AI;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCB
	/*@Error*/
	// End:0xCA
	foreach parentScript.allActorLabel(Class'ShockAI.ShockAI', AI, AILabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC9
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA9
		/*@Error*/
		AI.StopSpeech(SpeechEventLabel);
		goto J0xC9;
		AI.PlaySpeech(SpeechEventLabel);				
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
	// End:0xB2
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x6F
		if(bStopSpeech)
		{
			S = __NFUN_168__(__NFUN_168__(__NFUN_168__("AI with label", string(AILabel)), "will stop playing"), string(SpeechEventLabel));
			goto J0xAF;
			S = __NFUN_168__(__NFUN_168__(__NFUN_168__("AI with label", string(AILabel)), "will play"), string(SpeechEventLabel));
		}
		goto J0xD1;
		S = "AILabel is not set!";
		return;
		J0xAF:

		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Play a SpeechEvent on an AI"
	actionHelp="Play a SpeechEvent on an AI"
	Category="AI"
}