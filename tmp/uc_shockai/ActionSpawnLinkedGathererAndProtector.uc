class ActionSpawnLinkedGathererAndProtector extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<Protector> ProtectorTypeToSpawn;
var edfindable travel GathererVent AssociatedGathererVent;
var travel name ProtectorLabel;
var travel name GathererLabel;
var travel name ProtectorSpawnLocationLabel;
var travel name GathererSpawnLocationLabel;
var export editinline travel Container ProtectorLootContainer;
var export editinline travel Container GathererLootContainer;
var travel array<name> OverriddenProtectorArchetypeNames;
var travel array<name> OverriddenGathererArchetypeNames;
var travel bool bProtectorCorpseCanBeRemoved;
var travel bool bGathererCorpseCanBeRemoved;
var travel Gatherer.GathererVulnerableState GathererVulnerableState;
var travel bool bForceSpawn;

function Variable execute()
{
	local SpawningManager SpawningManager;
	local Gatherer SpawnedGatherer;
	local Protector SpawnedProtector;
	local name OverriddenGathererArchetypeName, OverriddenProtectorArchetypeName;
	local Range DummyRange;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x37F
	/*@Error*/
	// End:0x7B
	if(__NFUN_151__(OverriddenGathererArchetypeNames.Length, 0))
	{
		OverriddenGathererArchetypeName = OverriddenGathererArchetypeNames[__NFUN_167__(OverriddenGathererArchetypeNames.Length)];
		// End:0xAB
		if(__NFUN_151__(OverriddenProtectorArchetypeNames.Length, 0))
		{
			OverriddenProtectorArchetypeName = OverriddenProtectorArchetypeNames[__NFUN_167__(OverriddenProtectorArchetypeNames.Length)];
		}
		SpawningManager = SpawningManager(parentScript.Level.SpawningManager);
		SpawnedGatherer = Gatherer(SpawningManager.SpawnScriptedAI(AssociatedGathererVent.GathererClass, GathererSpawnLocationLabel, GathererLabel, GathererLootContainer, 'None', 0.0000000, 0.0000000, false, DummyRange, OverriddenGathererArchetypeName, bGathererCorpseCanBeRemoved, bForceSpawn));
	}
	SpawnedProtector = Protector(SpawningManager.SpawnScriptedAI(ProtectorTypeToSpawn, ProtectorSpawnLocationLabel, ProtectorLabel, ProtectorLootContainer, 'None', 0.0000000, 0.0000000, false, DummyRange, OverriddenProtectorArchetypeName, bProtectorCorpseCanBeRemoved, bForceSpawn));
	// End:0x2B0
	if(__NFUN_130__(__NFUN_119__(SpawnedGatherer, none), __NFUN_119__(SpawnedProtector, none)))
	{
		SpawnedGatherer.BecomePhysical();
		SpawnedGatherer.SetSkipExitFlag(true);
		SpawnedGatherer.SetEscort(SpawnedProtector);
		SpawnedGatherer.SetCurrentVent(AssociatedGathererVent);
		SpawnedProtector.SetCurrentGatherer(SpawnedGatherer);
		goto J0x37C;
		log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Only one or none of the AIs could be spawned by ", string(Name)), " in "), string(parentScript.Name)), ", destroying any orphans."));
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x35D
		/*@Error*/
		SpawnedGatherer.__NFUN_279__();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x37C
		/*@Error*/
		SpawnedProtector.__NFUN_279__();
		goto J0x40B;
		log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__("Didn't have enough information to spawn a linked gatherer and protector in ", string(Name)), " in "), string(parentScript.Name)));
	}
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DisplayProtectorTypes(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplayProtectorTypes(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string DisplayAITypeName(Class<Protector> ProtectorClass)
{
	// End:0x2B
	if(__NFUN_119__(ProtectorClass, none))
	{
		return string(ProtectorClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3B:

	CommanderAction
}

function OutputArchetypesToBox(LevelInfo Level, out array<name> S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).OutputArchetypesToBox(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Spawn Protector ", propertyDisplayString('ProtectorTypeToSpawn')), " at "), string(ProtectorSpawnLocationLabel)), "  and linked Gatherer at "), string(GathererSpawnLocationLabel));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

defaultproperties
{
	bProtectorCorpseCanBeRemoved=true
	bGathererCorpseCanBeRemoved=true
	GathererVulnerableState=1
	actionDisplayName="Spawn a linked Gatherer and Protector"
	actionHelp="Spawn a linked Gatherer and Protector"
	Category="AI"
}