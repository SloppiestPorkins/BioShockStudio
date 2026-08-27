class ActionSetSpawnerRepopulationState extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name SpawnerLabel;
var travel bool Flag;

function Variable execute()
{
	local SpawnerBase SpawnerIter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x86
	/*@Error*/
	// End:0x85
	foreach parentScript.Level.allActorLabel(Class'ShockAI.SpawnerBase', SpawnerIter, SpawnerLabel)
	{
		SpawnerIter.SetRepopulationState(Flag);				
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
	local string Insert;

	// End:0x1E
	if(Flag)
	{
		Insert = "to";
		goto J0x30;
		Insert = "to NOT";
	}
	S = __NFUN_168__(__NFUN_168__(__NFUN_168__("Set", propertyDisplayString('SpawnerLabel')), Insert), "spawn AIs");
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Set Spawner Repopulation State"
	actionHelp="Set whether a Spawner can spawn Repopulation AIs"
	Category="AI"
}