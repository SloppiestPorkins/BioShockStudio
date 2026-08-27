class ActionClearAIDamageStates extends Action
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

	// End:0xCB
	/*@Error*/
	// End:0xCA
	foreach parentScript.allActorLabel(Class'ShockAI.ShockAI', Iter, AILabel)
	{
		Iter.ClearShocked();
		Iter.ClearBurning();
		Iter.ClearFrozen();
		Iter.ClearBerserk();
		Iter.ClearSecurityBeacon();				
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
	// End:0x5C
	if(__NFUN_255__(AILabel, 'None'))
	{
		S = "AI with label will have its damage states cleared out.";
		goto J0x7B;
		S = "AILabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	J0x7B:

	CommanderAction
}

defaultproperties
{
	actionDisplayName="Clear Damage States on an AI"
	actionHelp="Clear Damage States on an AI"
	Category="AI"
}