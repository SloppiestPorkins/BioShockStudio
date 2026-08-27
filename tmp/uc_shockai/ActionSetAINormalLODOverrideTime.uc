class ActionSetAINormalLODOverrideTime extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel float LODOverrideTime;

function Variable execute()
{
	local int i;
	local ShockAI Iter;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCE
	/*@Error*/
	Iter = ShockAI(parentScript.Level.PawnList[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC0
	/*@Error*/
	Iter.SetNormalAILODOverrideTime(LODOverrideTime);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x83
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will be told to use normal LOD for "), string(LODOverrideTime)), " seconds.");
		goto J0x9F;
		S = "AILabel not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Set a AI to use Normal LOD for an amount of time"
	actionHelp="Set a AI to use Normal LOD for an amount of time"
	Category="AI"
}