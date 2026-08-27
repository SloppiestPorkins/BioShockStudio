class AIContainerInfo extends Object
	native
	editinlinenew;

var export editinline Container LootContainer;
var Class<ShockAI> AIType;

function DisplayAllAITypes(LevelInfo Level, out array< Class<ShockAI> > S)
{
	local SpawningManager SpawningManager;

	SpawningManager = SpawningManager(Level.SpawningManager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x61
	/*@Error*/
	SpawningManager.DisplayAllAITypes(Level, S);
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
