class ActionResetProtectorAttackTargets extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ProtectorLabel;

function Variable execute()
{
	local Protector Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	// End:0x6E
	foreach parentScript.dynamicActorLabel(Class'ShockAI.Protector', Iter, ProtectorLabel)
	{
		Iter.ResetAttackTargets();				
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
	// End:0x70
	if(__NFUN_255__(ProtectorLabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__("Protector with label ", string(ProtectorLabel)), " will have its Attack targets reset.");
		goto J0x96;
		S = "ProtectorLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Reset a Protector's Attack Targets"
	actionHelp="Reset a Protector's Attack Targets"
	Category="AI"
}