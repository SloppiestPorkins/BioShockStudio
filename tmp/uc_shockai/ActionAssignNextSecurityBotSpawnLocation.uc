class ActionAssignNextSecurityBotSpawnLocation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name SpawnLocationLabel;

function Variable execute()
{
	local SpawningManager SpawningManager;

	super.execute();
	SpawningManager = SpawningManager(parentScript.Level.SpawningManager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	SpawningManager.SetSecurityBotSpawnLocationLabel(SpawnLocationLabel);
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x7E
	if(__NFUN_255__(SpawnLocationLabel, 'None'))
	{
		S = __NFUN_112__("Tells the SpawningManager to spawn SecurityBots at Actor(s) with the Label ", string(SpawnLocationLabel));
		goto J0xA8;
		S = "SpawnLocationLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Assign the next spawn location for Security Bot(s)"
	actionHelp="Assign the next spawn location for Security Bot(s)"
	Category="AI"
}