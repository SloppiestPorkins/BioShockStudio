class ActionStartAIHeadTracking extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel name HeadTrackTargetLabel;
var travel bool bIsQuickLook;
var travel float Duration;
var travel Vector Offset;

function Variable execute()
{
	local Actor HeadTrackTarget;
	local ShockAI AI;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11A
	/*@Error*/
	HeadTrackTarget = findByLabel(Class'Engine.Actor', HeadTrackTargetLabel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11A
	/*@Error*/
	// End:0x119
	foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', AI, AILabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE6
		/*@Error*/
		AI.QuickLook(HeadTrackTarget, Duration, Offset);
		goto J0x118;
		AI.CasualLook(HeadTrackTarget, Duration, Offset);				
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
	// End:0xBB
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x8C
		if(__NFUN_255__(HeadTrackTargetLabel, 'None'))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will head track target with label "), string(HeadTrackTargetLabel));
			goto J0xB8;
			S = "HeadTrackTargetLabel is not set!";
		}
		goto J0xDA;
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
	actionDisplayName="Start AI Head Tracking"
	actionHelp="Start AI Head Tracking"
	Category="AI"
}