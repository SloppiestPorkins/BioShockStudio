class ActionGetNumAIsInSpawnZone extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name SpawnZoneName;
var travel Class<ShockAI> AITypeToCount;

function DisplayAITypes(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5C
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplayAllAITypes(Level, S, true);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string DisplayAITypeName(Class<ShockAI> AIClass)
{
	// End:0x2B
	if(__NFUN_119__(AIClass, none))
	{
		return string(AIClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3B:

	CommanderAction
}

function Variable execute()
{
	super.execute();
	return newTemporaryVariable(Class'Scripting.VariableFloat', string(SpawningManager(parentScript.Level.SpawningManager).GetNumAIsInSpawnZone(AITypeToCount, SpawnZoneName)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Get the number of ", string(AITypeToCount)), " in spawn zone: "), string(SpawnZoneName));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

defaultproperties
{
	AITypeToCount=Class'ShockAI.ShockAI'
	actionDisplayName="Get the number of AIs in a particular spawn zone."
	actionHelp="Get the number of AIs in a particular spawn zone."
	returnType=Class'Scripting.Variable'
	Category="AI"
}